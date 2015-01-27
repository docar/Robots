clc
clear obj

obj.Connection = database(DataBase.readSetup('DBName'),...
    'root','selena', 'Vendor','MySQL');

TimeFrames = DataBase.readSetup('TimeFrames');

obj.AllTickers = fetch(obj.Connection, [...
    ' SELECT * '...
    ' FROM tickers'...
    ]);

TableName = 'rts-3.13';

exec(obj.Connection,...
    ' SET max_heap_table_size = 1024*1024*2048');

exec(obj.Connection, [...
    ' DROP FUNCTION getPrice'...
    ]);
exec(obj.Connection, [...
    ' DROP PROCEDURE dorepeat'...
    ]);
exec(obj.Connection, [...
    ' CREATE FUNCTION getPrice(tradeID BIGINT)'...
    ' RETURNS FLOAT'...
    ' BEGIN '...
    ' SET @price = (SELECT price FROM `' TableName '` WHERE trade_id = tradeID);'...
    ' RETURN @price;'...
    ' END'...
    ]);

res = exec(obj.Connection, [...
    ' CREATE PROCEDURE dorepeat()'...
    ' BEGIN '...
    ' DECLARE minID BIGINT(14) ;'...
    ' DECLARE done INT DEFAULT FALSE;'...
    ' DECLARE minID_cur CURSOR FOR SELECT time_id FROM timeID_table ORDER BY time_id ASC;'...
    ' DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;'...
    ' DROP TABLE IF EXISTS result ;'...
    ' CREATE TABLE result '...
    ' (open FLOAT, high FLOAT, low FLOAT,'...
    ' close FLOAT, volume INT, time BIGINT, deals INT, PRIMARY KEY (time))'...
    ' ENGINE=MEMORY  ;'...
    ' DROP TABLE IF EXISTS timeID_table;'...
    ' CREATE TABLE timeID_table (time_id CHAR(14), PRIMARY KEY (time_id)) ENGINE=MEMORY ;'...
    ' INSERT INTO timeID_table SELECT DISTINCT SUBSTRING(time_id, 1, 14) '...
    ' FROM `'  TableName '`  ORDER BY trade_id;'...
    ' OPEN minID_cur;'...
    ' read_loop: LOOP'...
    '  IF done THEN'...
    '     LEAVE read_loop;'...
    '  END IF;'...
    ' FETCH minID_cur INTO minID;'...
    ' INSERT INTO result SELECT getPrice(MIN(trade_id)), MAX(price),  MIN(price), getPrice(MAX(trade_id)),'...
    ' SUM(amount), minID, COUNT(trade_id)'...
    ' FROM `' TableName '` WHERE time_id LIKE CONCAT(minID, ''%'') ORDER BY trade_id ASC' ...
    ' ON DUPLICATE KEY UPDATE'...
    ' time = VALUES(time);'...
    ' END LOOP;'...
    ' CLOSE minID_cur;'...
    ' DROP TABLE IF EXISTS `' TableName '_1min`;'...
    ' DROP TABLE timeID_table;'...
    ' END'...
    ]);
if ~isempty( res.message )
    disp(res.message)
end

res = exec(obj.Connection,'CALL dorepeat()');
if ~isempty( res.message )
    disp(res.message)
end

exec(obj.Connection, [...
    ' DROP FUNCTION getPrice'...
    ]);
exec(obj.Connection, [...
    ' DROP PROCEDURE dorepeat'...
    ]);
result = fetch(obj.Connection, [...
    ' SELECT * '...
    ' FROM result'...
    ]);

DataBase.createContractData( result, TableName );