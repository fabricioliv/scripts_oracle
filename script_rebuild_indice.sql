DECLARE
  vOwner   dba_indexes.owner%TYPE;            /* Index Owner            */
  vIdxName dba_indexes.index_name%TYPE;       /* Index Name             */
  vAnalyze VARCHAR2(100);                     /* String of Analyze Stmt */
  vCursor  NUMBER;                            /* DBMS_SQL cursor        */
  vNumRows INTEGER;                           /* DBMS_SQL return rows   */
  vHeight  index_stats.height%TYPE;           /* Height of index tree   */
  vLfRows  index_stats.lf_rows%TYPE;          /* Index Leaf Rows        */
  vDLfRows index_stats.del_lf_rows%TYPE;      /* Deleted Leaf Rows      */
  vDLfPerc   NUMBER;                          /* Del lf Percentage      */
  vMaxHeight NUMBER;                          /* Max tree height        */
  vMaxDel    NUMBER;                          /* Max del lf percentage  */
--
  CURSOR cGetIdx IS 
  SELECT owner,index_name
    FROM dba_indexes 
   WHERE upper(OWNER) not in ('SYS'); --definir owner
BEGIN
  /* Definir os valores máximos. Esta seção pode ser personalizada.*/
  vMaxHeight := 3;
  vMaxDel    := 20;
--
-- 
/* Para todo índice, valide estrutura */
  OPEN cGetIdx;
  LOOP
     FETCH cGetIdx INTO vOwner,vIdxName;
     EXIT WHEN cGetIdx%NOTFOUND;
     /* Abre DBMS_SQL cursor */
     vCursor := DBMS_SQL.OPEN_CURSOR;
    /* Configura string dinâmica para validar estrutura */
     
     vAnalyze := 'ANALYZE INDEX ' || vOwner || '.' || vIdxName || ' VALIDATE STRUCTURE';
     DBMS_SQL.PARSE(vCursor,vAnalyze,DBMS_SQL.V7);
     vNumRows := DBMS_SQL.EXECUTE(vCursor);
     /* Fecha DBMS_SQL cursor */
     DBMS_SQL.CLOSE_CURSOR(vCursor);
    -- 
     /* O índice precisa ser reconstruído?*/
     /* Em caso afirmativo, executa o comando */
     SELECT height,lf_rows,del_lf_rows INTO vHeight,vLfRows,vDLfRows
        FROM INDEX_STATS;
     IF vDLfRows = 0 THEN         /* Tratativa no caso de  div by zero */
        vDLfPerc := 0;
     ELSE
        vDLfPerc := (vDLfRows / vLfRows) * 100;
     END IF;
     IF (vHeight > vMaxHeight) OR (vDLfPerc > vMaxDel) THEN
        --DBMS_OUTPUT.PUT_LINE('ALTER INDEX ' || vOwner || '.' || vIdxName ||'REBUILD ONLINE PARALLEL';
		--DBMS_OUTPUT.PUT_LINE('noparallel'); 
		  DBMS_OUTPUT.PUT_LINE('INDEX ' || vOwner || '.' || vIdxName || '  NECESSITA DE REBUILD');
     END IF;

  END LOOP;
  CLOSE cGetIdx;
END;
/