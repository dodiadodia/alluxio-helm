package opa_auth_policy

import rego.v1

# -----------------------------------------------------------------------------
# --- Default Policy
# -----------------------------------------------------------------------------

# By default, deny all requests.
default allow := false

# -----------------------------------------------------------------------------
# --- Main Authorization Rules
# --- These are the top-level rules that determine the final 'allow' decision.
# -----------------------------------------------------------------------------

# Rule 1: SuperAdmins are allowed to do anything, bypassing all other checks.
allow if {
    user_is_superadmin
}

# Rule 2: For users who pass the base checks, allow GET access to globally allowed APIs.
allow if {
    base_checks_pass
    method_is_get
    api_in_global_allow_list
}

# Rule 3: Admins can list resources (i.e., a GET request with no specific path or ID).
allow if {
    base_checks_pass
    user_is_admin
    method_is_get
    request_is_for_listing
}

# Rule 4: Allow any user who passes base checks to GET resources if all requested paths are permitted.
allow if {
    base_checks_pass
    method_is_get
    all_request_paths_are_allowed
}

# Rule 5: Allow Admins to perform update actions if all requested paths are permitted.
allow if {
    base_checks_pass
    user_is_admin
    method_is_update
    all_request_paths_are_allowed
}

# Rule 6: Allow requests that provide an ID but no path.
# This handles a specific update scenario.
allow if {
    base_checks_pass
    user_is_admin
    method_is_update
    request_has_id_but_no_path
}

# Rule 7: Allow requests that provide an ID but no path.
# This handles a specific GET scenario.
allow if {
    base_checks_pass
    method_is_get
    request_has_id_but_no_path
}

# -----------------------------------------------------------------------------
# --- Core Logic Helpers
# -----------------------------------------------------------------------------

# Combines common checks for non-superadmin users to improve performance.
base_checks_pass if {
    not user_is_superadmin
    user_is_valid
    not api_in_global_deny_list
}

# Checks if all paths in the request are in the user's allow list and not in the deny list.
all_request_paths_are_allowed if {
    count(relevant_paths) > 0
    count({x | relevant_paths[x]; path_is_allowed(x)}) == count(relevant_paths)
    count({x | relevant_paths[x]; path_is_denied(x)}) == 0
}

# Determines if the request is a "listing" operation (no ID and no paths).
request_is_for_listing if {
    not request_has_id
    count(relevant_paths) == 0
}

# Determines if the request contains an ID but no paths.
request_has_id_but_no_path if {
    request_has_id
    count(relevant_paths) == 0
}

# -----------------------------------------------------------------------------
# --- Permission Detail Helpers
# -----------------------------------------------------------------------------

# Checks if a path is in the user's allowed prefixes.
path_is_allowed(path) if {
    some i, j
    some group in input_groups
    group == data.groups[i].group
    clean_path := trim_suffix(path, "/")
    clean_prefix := trim_suffix(data.groups[i].allow.pathPrefixes[j].prefix, "/")
    strings.any_prefix_match(clean_path, clean_prefix)
    is_valid_prefix_match(clean_path, clean_prefix)
    api_is_valid_for_path_rule(data.groups[i].allow.pathPrefixes[j])
}

# Checks if a path is in the user's denied prefixes.
path_is_denied(path) if {
    some i, j
    some group in input_groups
    group == data.groups[i].group
    clean_path := trim_suffix(path, "/")
    clean_prefix := trim_suffix(data.groups[i].deny.pathPrefixes[j].prefix, "/")
    strings.any_prefix_match(clean_path, clean_prefix)
    is_valid_prefix_match(clean_path, clean_prefix)
    api_is_valid_for_path_rule(data.groups[i].deny.pathPrefixes[j])
}

# Validates that the prefix match is legitimate.
# This rule is true if the prefix is an exact match to the path.
is_valid_prefix_match(path, prefix) if {
    strings.any_prefix_match(path, prefix)
    suffix := trim_prefix(path, prefix)
    suffix == ""
}

# This rule is true if the prefix matches a directory boundary.
# Example: prefix "/a/b" matches path "/a/b/c".
is_valid_prefix_match(path, prefix) if {
    strings.any_prefix_match(path, prefix)
    suffix := trim_prefix(path, prefix)
    startswith(suffix, "/")
}

# Checks if the current API is valid for the given path rule.
# Rule 1: If the path rule does not specify an 'apis' list, it applies to all APIs.
api_is_valid_for_path_rule(rule) if {
    not rule.apis
}

# Rule 2: If the path rule specifies an 'apis' list, the current API must be in that list.
api_is_valid_for_path_rule(rule) if {
    input_api in rule.apis
}

# -----------------------------------------------------------------------------
# --- Request Parsing Helpers
# -----------------------------------------------------------------------------

# Extract the API endpoint from the request path.
input_api := split(input.path, "/v1")[1]

# HTTP method checks.
method_is_get if input.method == "GET"
method_is_update if input.method != "GET"

# Extracts paths from multiple possible locations in the request.
# Uses the 'contains' keyword to incrementally build the set of paths.
paths_from_request contains path if {
    path := input.query.path[0]
}

paths_from_request contains path if {
    path := input.parsed_body.path
}

paths_from_request contains path if {
    path := input.parsed_body.paths[_]
}

paths_from_request contains path if {
    path := input.parsed_body.index
}

# Collects all non-empty paths from the request for validation.
relevant_paths := {p | some p in paths_from_request; p != ""}

# Checks if the request contains an ID.
request_has_id if input.parsed_body.id != ""
request_has_id if input.query.id != ""

# Global API list checks.
api_in_global_deny_list if input_api in data.denyApis
api_in_global_allow_list if input_api in data.allowApis

# -----------------------------------------------------------------------------
# --- User & Role Helpers
# -----------------------------------------------------------------------------

claims := payload if {
    token := input.header.Authorization
    count(token) != 0
    startswith(token[0], "Bearer ")
    bearer_token := substring(token[0], count("Bearer "), -1)
    [_, payload, _] := io.jwt.decode(bearer_token)
}

else := user_info if {
    token := input.header.Authorization
    count(token) != 0
    not startswith(token[0], "Bearer ")
    base64.is_valid(token[0])
    ui = base64.decode(token[0])
    json.is_valid(ui)
    user_info = json.unmarshal(ui)
}

default input_roles := []

input_roles := claims.{{ .authentication.oidc.roleFieldName }} if {
    claims.{{ .authentication.oidc.roleFieldName }} != ""
    is_array(claims.{{ .authentication.oidc.roleFieldName }})
}

else := [claims.{{ .authentication.oidc.roleFieldName }}] if {
    claims.{{ .authentication.oidc.roleFieldName }} != ""
    is_string(claims.{{ .authentication.oidc.roleFieldName }})
}

else := claims.role if  {
    claims.role != ""
    is_array(claims.role)
}

else := [claims.role] if {
    claims.role != ""
    is_string(claims.role)
}

default input_groups := []

input_groups := claims.{{ .authentication.oidc.groupFieldName }} if {
    claims.{{ .authentication.oidc.groupFieldName }} != ""
    is_array(claims.{{ .authentication.oidc.groupFieldName }})
}

else := [claims.{{ .authentication.oidc.groupFieldName }}] if {
    claims.{{ .authentication.oidc.groupFieldName }} != ""
    is_string(claims.{{ .authentication.oidc.groupFieldName }})
}

else := claims.group if {
    claims.group != ""
    is_array(claims.group)
}

else := [claims.group] if {
    claims.group != ""
    is_string(claims.group)
}

user_is_valid if {
    count(input_roles) > 0
    count(input_groups) > 0
}

user_is_superadmin if {
    count(input_roles) > 0
    some i
    some role in input_roles
    role == data.superAdmin[i]
}

user_is_admin if {
    some i
    some role in input_roles
    role == data.groupAdmin[i]
}
