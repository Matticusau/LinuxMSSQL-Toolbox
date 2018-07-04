------------------------------
-- Monitor AG Replica health
-- Author:	MLavery
-- Date:	18/06/2018
--
-- When		Who			What
-- 2018-07-04   MLavery     Added NOCOUNT
-- 
------------------------------

SET NOCOUNT ON;

-- 1. Monitor health of the Ag Database
--    Alternatively use the AG Dashboard
SELECT n.group_name
    , n.replica_server_name
    , n.node_name
    , rs.role_desc
    , db_name(drs.database_id) as 'DBName'
    , drs.synchronization_state_desc
    , drs.synchronization_health_desc
    , drs.redo_queue_size
    , drs.redo_rate
FROM sys.dm_hadr_availability_replica_cluster_nodes n 
JOIN sys.dm_hadr_availability_replica_cluster_states cs 
    ON n.replica_server_name = cs.replica_server_name 
JOIN sys.dm_hadr_availability_replica_states rs  
    ON rs.replica_id = cs.replica_id 
JOIN sys.dm_hadr_database_replica_states drs 
    ON rs.replica_id=drs.replica_id
ORDER BY n.group_name, n.replica_server_name, db_name(drs.database_id)

SET NOCOUNT OFF;
