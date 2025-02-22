CREATE OR REPLACE FUNCTION grest.native_script_list()
RETURNS TABLE (
  script_hash text,
  creation_tx_hash text,
  type scripttype,
  script jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ENCODE(script.hash, 'hex'),
    ENCODE(tx.hash, 'hex'),
    script.type,
    script.json
  FROM script
    INNER JOIN tx ON tx.id = script.tx_id
  WHERE script.type IN ('timelock', 'multisig');
END;
$$;

COMMENT ON FUNCTION grest.native_script_list IS 'Get a list of all native(multisig/timelock) script hashes with creation tx hash, type and script in json format.'; --noqa: LT01
