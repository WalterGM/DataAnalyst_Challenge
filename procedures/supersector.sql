CREATE OR REPLACE PROCEDURE import_supersector(chunk_size INT)
AS $$

DECLARE
    file_handle TEXT;
    data_line TEXT;
    lines_read INT := 0;
	is_header BOOLEAN := TRUE;
	data_array TEXT[];

BEGIN
    file_handle := 'C:\Temp\ce.supersector.txt'; -- Replace with the actual path to your file
    FOR data_line IN (SELECT unnest(string_to_array(pg_read_file(file_handle), E'\n')) AS line)
    LOOP
        IF is_header THEN
            is_header := FALSE; -- Skip the first line (header)
            CONTINUE;
        END IF;
		RAISE NOTICE 'my_variable: %', data_line;
		data_array := regexp_split_to_array(data_line, E'[\t\n]+');
		        IF array_length(data_array, 1) <> 2 THEN
            CONTINUE; -- Skip rows that do not have 2 columns
        END IF;
        EXECUTE 'INSERT INTO "ce.supersector" (supersector_code, supersector_name) VALUES ($1, $2)' USING data_array[1]:: bigint, data_array[2];
        IF lines_read >= chunk_size THEN
            COMMIT; -- Commit the current transaction
            lines_read := 0; -- Reset the counter
        END IF;
    END LOOP;
    IF lines_read > 0 THEN
        COMMIT; -- Commit any remaining data
    END IF;
END;

$$
LANGUAGE plpgsql;