DROP TABLE IF EXISTS hd_pulse_raw;
CREATE TABLE hd_pulse_raw AS
SELECT * FROM read_csv_auto('data/raw/HDPulse_data_export (1).csv', header=True);
