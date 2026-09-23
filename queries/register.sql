-- name: Register :exec
-- The two ids are bound here rather than in the INSERTs so each carries its
-- own name; a parameter written straight into a column is named for that
-- column, and both tables call theirs id.
WITH args AS (
  SELECT $1::uuid AS identity_id, $2::bytea AS credential_id
), inserted AS (
  INSERT INTO identity (id, name, display_name, creation_date, last_authenticated_date, grant_hash)
  SELECT args.identity_id, $3, $4, $5, $6, $7
    FROM args
  RETURNING id
)
INSERT INTO credential (id, identity_id, sign_count, uv_initialized, backup_state,
                        attestation_object, attestation_client_data_json, transports, rp_id)
SELECT args.credential_id, inserted.id, $8, $9, $10, $11, $12, $13, $14
  FROM args, inserted;
