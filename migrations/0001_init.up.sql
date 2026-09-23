CREATE SCHEMA webauthn_data;

CREATE TYPE webauthn_data.attachment AS ENUM ('platform', 'cross-platform');

CREATE TYPE webauthn_data.user_verification AS ENUM ('discouraged', 'preferred', 'required');

CREATE TYPE webauthn_data.attestation_conveyance AS ENUM ('none', 'indirect', 'direct', 'enterprise');

CREATE TYPE webauthn_data.attestation_type AS ENUM ('none', 'self', 'basic', 'attca', 'anonca');

CREATE TYPE webauthn_data.revocation_mode AS ENUM ('unchecked', 'soft_fail', 'hard_fail');

-- A relying party is one WebAuthn deployment of a realm: the RP a ceremony
-- runs against and the policy every ceremony under it is held to. A realm
-- holds one row per relying party it operates.
--
-- Discoverable credentials are a system requirement rather than a control:
-- login discovers the credential before asking for a challenge, so a
-- non-discoverable credential could never be selected.
CREATE TABLE webauthn_data.realm (
    realm_id                       UUID      NOT NULL REFERENCES realm_data.realm (id) ON DELETE CASCADE,

    -- The RP ID, a registrable domain suffix of every origin below.
    rp_id                          TEXT      NOT NULL,
    rp_name                        TEXT      NOT NULL,

    -- What the ceremony asks the client for.
    attachment                     webauthn_data.attachment,
    user_verification              webauthn_data.user_verification NOT NULL,
    attestation                    webauthn_data.attestation_conveyance NOT NULL,
    attestation_formats            TEXT[]    NOT NULL DEFAULT '{}',
    hints                          TEXT[]    NOT NULL DEFAULT '{}',

    -- COSE algorithm identifiers, most preferred first.
    algorithms                     INTEGER[] NOT NULL DEFAULT '{}',

    -- Opaque extension inputs, as the client receives them.
    extensions                     JSONB     NOT NULL DEFAULT '{}',

    -- Milliseconds the client is asked to allow for the ceremony.
    timeout                        INTEGER   NOT NULL,

    -- What a completed ceremony is held to.
    origins                        TEXT[]    NOT NULL DEFAULT '{}',
    origin_enforced                BOOLEAN   NOT NULL,
    cross_origin_enforced          BOOLEAN   NOT NULL,
    top_origins                    TEXT[]    NOT NULL DEFAULT '{}',
    rp_id_hash_mismatch_allowed    BOOLEAN   NOT NULL,
    backup_flags_enforced          BOOLEAN   NOT NULL,
    backup_eligibility_enforced    BOOLEAN   NOT NULL,
    sign_count_enforced            BOOLEAN   NOT NULL,
    uv_transition_allowed          BOOLEAN   NOT NULL,

    -- The attestation statement formats and resulting types a registration may
    -- present, and the material a certificate-based one is chained against.
    allowed_attestation_formats    TEXT[]    NOT NULL DEFAULT '{}',
    allowed_attestation_types      webauthn_data.attestation_type[] NOT NULL DEFAULT '{}',
    trust_anchors                  BYTEA[]   NOT NULL DEFAULT '{}',
    intermediate_certificates      BYTEA[]   NOT NULL DEFAULT '{}',

    -- Revocation status is read from the responder or distribution point named
    -- in the certificate itself, or from a list supplied here when the
    -- deployment makes no outbound requests.
    revocation_mode                webauthn_data.revocation_mode NOT NULL,
    certificate_revocation_lists   BYTEA[]   NOT NULL DEFAULT '{}',

    attestation_downgrade_allowed  BOOLEAN   NOT NULL,
    login_attestation_enforced     BOOLEAN   NOT NULL,

    PRIMARY KEY (realm_id, rp_id)
);

-- A credential is a public key an authenticator created for an identity during
-- a WebAuthn registration ceremony. Register commits one beside the membership
-- it references, in one transaction; Login reads it and advances its counters
-- in the same transaction that writes the membership's grant.
--
-- The credential type is the fixed WebAuthn value "public-key" and is not
-- stored. The public key and backup eligibility are read from the retained
-- attestation object and are not stored beside it.
CREATE TABLE webauthn_data.credential (
    -- The credential id the authenticator chose, at most 1023 bytes.
    id                           BYTEA   PRIMARY KEY CHECK (octet_length(id) <= 1023),

    identity_id                  UUID    NOT NULL,
    realm_id                     UUID    NOT NULL,

    -- Always true, so this row can only reference a membership a credential is
    -- allowed to hang off.
    credentialable               BOOLEAN NOT NULL DEFAULT TRUE CHECK (credentialable),

    -- The relying party the credential was registered under.
    rp_id                        TEXT    NOT NULL,

    sign_count                   BIGINT  NOT NULL,
    uv_initialized               BOOLEAN NOT NULL,
    transports                   TEXT[]  NOT NULL DEFAULT '{}',
    backup_state                 BOOLEAN NOT NULL,

    -- The registration evidence, retained for a later attestation-trust
    -- re-evaluation.
    attestation_object           BYTEA   NOT NULL,
    attestation_client_data_json BYTEA   NOT NULL,

    -- One replaceable, single-use challenge per credential. Time is not part
    -- of validity; login atomically consumes this slot in the transaction
    -- that writes the membership's grant.
    current_login_challenge      BYTEA
        CHECK (current_login_challenge IS NULL OR octet_length(current_login_challenge) = 32),

    FOREIGN KEY (realm_id, identity_id, credentialable)
        REFERENCES identity_data.realm_membership (realm_id, identity_id, credentialable) ON DELETE CASCADE,
    FOREIGN KEY (realm_id, rp_id)
        REFERENCES webauthn_data.realm (realm_id, rp_id)
);

CREATE INDEX credential_membership ON webauthn_data.credential (realm_id, identity_id);
