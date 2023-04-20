function script_init()
  return 0
end

function script_deinit()
end

local http_client = dovecot.http.client {
    timeout = 2000;
    max_attempts = 3;
}

function auth_passdb_lookup(req)
  local auth_request = http_client:request {
    url = "http://{{ ADMIN_ADDRESS }}/internal/auth/email";
  }
  auth_request:add_header('Auth-Port', req.local_port)
  auth_request:add_header('Auth-User', req.user)
  auth_request:add_header('Auth-Pass', req.password)
  auth_request:add_header('Auth-Protocol', 'sieve')
  auth_request:add_header('Client-IP', req.remote_ip)
  auth_request:add_header('Auth-SSL', req.secured)
  auth_request:add_header('Auth-Method', req.mechanism)
  local auth_response = auth_request:submit()
  local resp_status = auth_response:status()

  if resp_status == 200
  then
    if auth_response:header('Auth-Status') == 'OK'
    then
      return dovecot.auth.PASSDB_RESULT_OK, "proxy=y host={{ IMAP_ADDRESS }} nopassword=Y"
    else
      return dovecot.auth.PASSDB_RESULT_PASSWORD_MISMATCH, ""
    end
  else
    return dovecot.auth.PASSDB_RESULT_INTERNAL_FAILURE, ""
  end
end
