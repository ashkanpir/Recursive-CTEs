-- Method without Recursive CTE:
-- This approach attempts to find all followers of 'WilliamEagle6815',
-- up to 4 levels deep, by explicitly joining the 'follows' table multiple times.
-- Each UNION block represents a level of followers (direct followers, followers of followers, etc.).

SELECT DISTINCT f1.follower_id AS follower_id
FROM users u
JOIN follows f1 ON u.user_id = f1.followee_id
WHERE u.user_name = 'WilliamEagle6815'

UNION

SELECT DISTINCT f2.follower_id
FROM users u
JOIN follows f1 ON u.user_id = f1.followee_id
JOIN follows f2 ON f1.follower_id = f2.followee_id
WHERE u.user_name = 'WilliamEagle6815'

UNION

SELECT DISTINCT f3.follower_id
FROM users u
JOIN follows f1 ON u.user_id = f1.followee_id
JOIN follows f2 ON f1.follower_id = f2.followee_id
JOIN follows f3 ON f2.follower_id = f3.followee_id
WHERE u.user_name = 'WilliamEagle6815'

UNION

SELECT DISTINCT f4.follower_id
FROM users u
JOIN follows f1 ON u.user_id = f1.followee_id
JOIN follows f2 ON f1.follower_id = f2.followee_id
JOIN follows f3 ON f2.follower_id = f3.followee_id
JOIN follows f4 ON f3.follower_id = f4.followee_id
WHERE u.user_name = 'WilliamEagle6815'
ORDER BY follower_id
LIMIT 10;

-- Method with Recursive CTE:
-- This approach uses a recursive CTE to dynamically find all followers of 'WilliamEagle6815',
-- up to 4 levels deep, in a more efficient and scalable manner. The recursive part expands the follower network
-- by one level at each iteration until it reaches the depth limit of 4.

WITH RECURSIVE UserConnections AS (
    -- Base case: Direct followers of 'WilliamEagle6815'.
    SELECT 
        f.follower_id, 
        1 AS depth  -- Starting depth level is 1 for direct followers.
    FROM 
        follows f
    JOIN 
        users u ON f.followee_id = u.user_id
    WHERE 
        u.user_name = 'WilliamEagle6815'
    
    UNION ALL
    
    -- Recursive case: Expands the follower network by one level at each iteration.
    SELECT 
        f.follower_id, 
        uc.depth + 1  -- Increment depth level to track how deep in the follower network we are.
    FROM 
        follows f
    JOIN 
        UserConnections uc ON f.followee_id = uc.follower_id
    WHERE 
        uc.depth < 4  -- Limit the recursion depth to 4 levels of followers.
)
SELECT DISTINCT 
    follower_id  -- Select unique follower IDs from the recursive CTE results.
FROM 
    UserConnections
ORDER BY 
    follower_id  -- Order the results by follower ID.
LIMIT 10;  -- Limit the result set to the first 10 entries for brevity.
