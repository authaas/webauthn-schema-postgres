-- name: Register :exec
-- The ids and the two creation dates are bound here rather than in the
-- INSERTs so each carries its own name; a parameter written straight into a
-- column is named for that column, and the three tables collide on id and on
-- creation_date.
WITH args AS (
  SELECT $1::uuid   AS identity_id,
         $2::uuid   AS realm_id,
         $3::bytea  AS credential_id,
         $4::bigint AS identity_creation_date,
         $5::bigint AS membership_creation_date
), identity_inserted AS (
  INSERT INTO identity_data.identity (id, creation_date)
  SELECT args.identity_id, args.identity_creation_date
    FROM args
  RETURNING id
), membership_inserted AS (
  INSERT INTO identity_data.realm_membership (identity_id, realm_id, name, display_name,
                                              creation_date, last_authenticated_date,
                                              grant_hash, credentialable, nbf, exp)
  SELECT identity_inserted.id, args.realm_id, $6, $7,
         args.membership_creation_date, $8,
         $9, TRUE, $10, $11
    FROM args, identity_inserted
  RETURNING identity_id, realm_id
)
INSERT INTO webauthn_data.credential (id, identity_id, realm_id, rp_id, sign_count, uv_initialized,
                                      backup_state, attestation_object,
                                      attestation_client_data_json, transports)
SELECT args.credential_id, membership_inserted.identity_id, membership_inserted.realm_id,
       $12, $13, $14, $15, $16, $17, $18
  FROM args, membership_inserted;
