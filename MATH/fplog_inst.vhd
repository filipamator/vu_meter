fplog_inst : fplog PORT MAP (
		clock	 => clock_sig,
		data	 => data_sig,
		nan	 => nan_sig,
		result	 => result_sig,
		zero	 => zero_sig
	);
