------------------------------
-- Monitor AG Replica Roles
-- Author:	MLavery
-- Date:	18/06/2018
--
-- When		Who			What
-- 
------------------------------

-- 1. Monitor Replica Roles of the AG
--    Alternatively use the AG Dashboard
SELECT n.group_name
    , n.replica_server_name
    , n.node_name
    , rs.role_desc 
FROM sys.dm_hadr_availability_replica_cluster_nodes n 
JOIN sys.dm_hadr_availability_replica_cluster_states cs 
    ON n.replica_server_name = cs.replica_server_name 
JOIN sys.dm_hadr_availability_replica_states rs  
    ON rs.replica_id = cs.replica_id
ORDER BY group_name, replica_server_name
