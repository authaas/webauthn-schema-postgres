-- name: GetRelyingParty :one
SELECT *
  FROM webauthn_data.realm
 WHERE realm_id = $1
   AND rp_id = $2;
