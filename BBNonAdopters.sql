/**************************/
/**** BB NON-ADOPTERS  ****/
/****    SAM TIMME     ****/
/**** EMORY UNIVERSITY ****/
/**** INSTRUCTURECON17 ****/
/**************************/

SELECT potentialAdopters.publicPersonID /* This is the value I will match users on in Canvas Data, since it's also our Integration ID. */
FROM (
	SELECT u.pk1, u.batch_uid AS publicPersonID 
	FROM bb_bb60.users u 
    LEFT JOIN (
		SELECT u.pk1, COUNT(DISTINCT cm.course_id) AS count
		FROM course_main cm 
		JOIN course_term ct ON ct.crsmain_pk1 = cm.pk1
		JOIN course_users cu ON cu.crsmain_pk1 = cm.pk1
		JOIN users u ON u.pk1 = cu.users_pk1
		WHERE cm.row_status = 0 /* Enabled course */
		AND ct.term_pk1 IN (SELECT pk1 FROM term WHERE sourcedid_id IN ('FA16','SP17'))
		AND cu.row_status = 0 /* Enabled enrollment */
		AND cu.role = 'P' /* Teacher enrollment */
		AND cm.course_name NOT LIKE '%Dissertation%' /* Some course name patterns we don't expect would use the LMS. */
		GROUP BY u.pk1
    ) transition ON transition.pk1 = u.pk1
	LEFT JOIN 
		(SELECT u.pk1, COUNT(DISTINCT cm.course_id) as count
		FROM course_main cm 
		JOIN course_term ct ON ct.crsmain_pk1 = cm.pk1
		JOIN course_users cu ON cu.crsmain_pk1 = cm.pk1
		JOIN users u ON u.pk1 = cu.users_pk1
		WHERE cm.row_status = 0 
		AND ct.term_pk1 IN (SELECT pk1 FROM term WHERE sourcedid_id IN ('FA14','SP15','FA15','SP16'))
		AND cu.row_status = 0
		AND cu.role = 'P'
		AND cm.course_name NOT LIKE '%Dissertation%' /* Some course name patterns we don't expect would use the LMS. */
		GROUP BY u.pk1
    ) priorYears ON priorYears.pk1 = u.pk1
    WHERE transition.count IS NOT NULL 
    AND priorYears.count IS NOT NULL
) potentialAdopters
LEFT JOIN (
    SELECT u.pk1, count(*) as count 
    FROM users u
    JOIN course_users cu ON cu.users_pk1 = u.pk1
    JOIN (
		SELECT cm.pk1 AS crsmain_pk1,
		COUNT(DISTINCT ann.pk1) AS ann,
		COUNT(DISTINCT cc.pk1)  AS cc
		FROM course_main cm 
		JOIN course_term ct ON ct.crsmain_pk1 = cm.pk1
		JOIN course_users cu ON cu.crsmain_pk1 = cm.pk1
		LEFT JOIN course_contents cc ON cc.crsmain_pk1 = cm.pk1
		LEFT JOIN announcements ann ON ann.crsmain_pk1 = cm.pk1
		WHERE ct.term_pk1 IN (SELECT pk1 FROM term WHERE sourcedid_id IN ('FA14','SP15','FA15','SP16','FA16','SP17'))
		AND cm.course_name NOT LIKE '%Dissertation%' /* Some course name patterns we don't expect would use the LMS. */
		AND cm.row_status = 0
		AND cu.role = 'S' /* Student enrollment */
		AND cu.last_access_date IS NOT NULL
		GROUP BY cm.pk1
	) courseActivity on courseActivity.crsmain_pk1 = cu.crsmain_pk1
    WHERE cu.row_status = 0 /* Enabled enrollment */
    AND cu.role  = 'P' /* Teacher enrollment */
    AND (ccc > 3
    OR   ann >= 1) /* Our blank course template includes three empty content areas, which create three records on the bb_bb60.course_contents table. So, the count from that table must be greater than 3 to indicate activity. */
    GROUP BY u.pk1
) teachersInActiveCourses ON teachersInActiveCourses.pk1 = potentialAdopters.pk1
WHERE teachersInActiveCourses.count IS NULL /* This selects the Non-Adopters by ruling out teachers with an active course count. */
;
