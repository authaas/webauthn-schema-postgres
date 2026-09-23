-- name: Login :execrows
-- Eligibility is settled before the challenge is consumed, so a membership
-- outside its validity window leaves the challenge in place.
WITH eligible AS (
  SELECT credential.id
    FROM webauthn_data.credential
   WHERE credential.id = $1
     AND credential.current_login_challenge = $2
     AND identity_data.assumable(credential.realm_id, credential.identity_id)
), consumed AS (
  UPDATE webauthn_data.credential
     SET sign_count = $3, backup_state = $4, uv_initialized = $5, current_login_challenge = NULL
   WHERE credential.id IN (SELECT eligible.id FROM eligible)
  RETURNING identity_id, realm_id
)
SELECT identity_data.assume(consumed.realm_id, consumed.identity_id, $6, $7)
  FROM consumed;
