-- name: GetCredential :one
SELECT *
  FROM webauthn_data.credential
 WHERE id = $1;
