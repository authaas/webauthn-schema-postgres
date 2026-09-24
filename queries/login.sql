-- name: Login :execrows
WITH consumed AS (
  UPDATE webauthn_data.credential
     SET sign_count = $3, backup_state = $4, uv_initialized = $5, current_login_challenge = NULL
   WHERE credential.id = $1
     AND credential.current_login_challenge = $2
  RETURNING identity_id, realm_id
)
SELECT identity_data.assume(consumed.realm_id, consumed.identity_id, $6, $7)
  FROM consumed;
