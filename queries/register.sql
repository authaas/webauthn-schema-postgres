-- name: Register :exec
WITH inserted AS (
  INSERT INTO principal (id, name, display_name, creation_date, last_authenticated_date, grant_hash)
  VALUES ($1, $2, $3, $4, $5, $6)
  RETURNING id
)
INSERT INTO credential (id, principal_id, sign_count, uv_initialized, backup_state,
                        attestation_object, attestation_client_data_json, transports, rp_id)
SELECT $7, inserted.id, $8, $9, $10, $11, $12, $13, $14
  FROM inserted;
