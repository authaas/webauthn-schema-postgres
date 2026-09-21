-- name: GetCredential :one
SELECT *
  FROM credential
 WHERE id = $1;
