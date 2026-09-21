-- name: SetLoginChallenge :execrows
UPDATE credential SET current_login_challenge = $2 WHERE id = $1;
