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

-- 1. Monitor health of the Ag Replica
--    Alternatively use the AG Dashboard
SELECT ag.name [ag_name]
	, ar.replica_server_name
	-- , ar.endpoint_url
	-- , ar.availability_mode
	, ar.availability_mode_desc
	-- , ar.failover_mode
	, ar.failover_mode_desc
	-- , ar.seeding_mode
	, ar.seeding_mode_desc
	-- , ars.role
	, ars.role_desc
	-- , ars.connected_state
	, ars.connected_state_desc
	--, ars.synchronization_health
	, ars.synchronization_health_desc
FROM sys.availability_groups ag
INNER JOIN sys.availability_replicas ar
	ON ar.group_id = ag.group_id
INNER JOIN sys.dm_hadr_availability_replica_states ars
	ON ars.replica_id = ar.replica_id
	AND ars.group_id = ar.group_id

SET NOCOUNT OFF;
