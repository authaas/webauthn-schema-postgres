-- name: GetCredential :one
SELECT id, principal_id, sign_count, uv_initialized, backup_state,
       attestation_object, attestation_client_data_json, transports, rp_id, current_login_challenge
  FROM credential
 WHERE id = $1;
