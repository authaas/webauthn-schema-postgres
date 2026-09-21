-- name: Login :execrows
WITH consumed AS (
  UPDATE credential
     SET sign_count = $3, backup_state = $4, uv_initialized = $5, current_login_challenge = NULL
   WHERE id = $1 AND current_login_challenge = $2
  RETURNING principal_id
)
UPDATE principal
   SET grant_hash = $6, last_authenticated_date = $7
  FROM consumed
 WHERE principal.id = consumed.principal_id;
