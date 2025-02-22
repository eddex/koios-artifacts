CREATE OR REPLACE FUNCTION grest.epoch_info(_epoch_no numeric DEFAULT NULL, _include_next_epoch boolean DEFAULT FALSE)
RETURNS TABLE (
  epoch_no word31type,
  out_sum text,
  fees text,
  tx_count word31type,
  blk_count word31type,
  start_time integer,
  end_time integer,
  first_block_time integer,
  last_block_time integer,
  active_stake text,
  total_rewards text,
  avg_blk_reward text
)
LANGUAGE plpgsql
AS $$
DECLARE
  shelley_epoch_duration numeric := (select epochlength::numeric * slotlength::numeric AS epochduration FROM grest.genesis);
  shelley_ref_epoch numeric := (select (ep.epoch_no::numeric + 1) FROM epoch_param ep ORDER BY ep.epoch_no LIMIT 1);
  shelley_ref_time numeric := (select ei.i_first_block_time FROM grest.epoch_info_cache ei where ei.epoch_no = shelley_ref_epoch);
BEGIN
  RETURN QUERY
  SELECT
    ei.epoch_no,
    ei.i_out_sum::text AS tx_output_sum,
    ei.i_fees::text AS tx_fees_sum,
    ei.i_tx_count AS tx_count,
    ei.i_blk_count AS blk_count,
    CASE
      WHEN ei.epoch_no < shelley_ref_epoch THEN
        ei.i_first_block_time::integer
      ELSE
        (shelley_ref_time + (ei.epoch_no - shelley_ref_epoch) * shelley_epoch_duration)::integer
    END AS start_time,
    CASE
      WHEN ei.epoch_no < shelley_ref_epoch THEN
        (ei.i_first_block_time + shelley_epoch_duration)::integer
      ELSE
        (shelley_ref_time + ((ei.epoch_no + 1) - shelley_ref_epoch) * shelley_epoch_duration)::integer
    END AS end_time,
    ei.i_first_block_time::integer AS first_block_time,
    ei.i_last_block_time::integer AS last_block_time,
    eas.amount::text AS active_stake,
    ei.i_total_rewards::text AS total_rewards,
    ei.i_avg_blk_reward::text AS avg_blk_reward
  FROM
    grest.epoch_info_cache AS ei
    LEFT JOIN grest.epoch_active_stake_cache AS eas ON eas.epoch_no = ei.epoch_no
  WHERE
    CASE WHEN _epoch_no IS NULL THEN
      ei.epoch_no <= (SELECT MAX(epoch.no) FROM public.epoch)
    ELSE
      ei.epoch_no = _epoch_no
    END
    AND
    (_include_next_epoch OR ei.i_first_block_time::integer is not null);
END;
$$;

COMMENT ON FUNCTION grest.epoch_info IS 'Get the epoch information, all epochs if no epoch specified. If _include_next_epoch is set to true, also return active stake calculation for next epoch if available'; -- noqa: LT01
