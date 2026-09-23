-- name: SetLoginChallenge :execrows
UPDATE webauthn_data.credential SET current_login_challenge = $2 WHERE id = $1;
