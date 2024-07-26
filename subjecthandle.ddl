DELIMITER //

CREATE PROCEDURE HandleSubjectChange()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE req_student_id VARCHAR(50);
    DECLARE req_subject_id VARCHAR(50);
    DECLARE current_subject_id VARCHAR(50);

    -- Cursor to loop through each request in the SubjectRequest table
    DECLARE request_cursor CURSOR FOR
        SELECT StudentId, SubjectId FROM SubjectRequest;

    -- Handler for the end of the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    OPEN request_cursor;

    request_loop: LOOP
        FETCH request_cursor INTO req_student_id, req_subject_id;
        IF finished THEN
            LEAVE request_loop;
        END IF;

        -- Check the current valid subject for the student
        SELECT SubjectId INTO current_subject_id
        FROM SubjectAllotments
        WHERE StudentId = req_student_id AND Is_valid = 1;

        IF current_subject_id IS NULL THEN
            -- If student does not have any subject allotted yet, insert the new request
            INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_valid)
            VALUES (req_student_id, req_subject_id, 1);
        ELSEIF current_subject_id != req_subject_id THEN
            -- If the current subject is different from the requested subject
            -- Mark the current subject as invalid
            UPDATE SubjectAllotments
            SET Is_valid = 0
            WHERE StudentId = req_student_id AND SubjectId = current_subject_id;

            -- Insert the new subject as valid
            INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_valid)
            VALUES (req_student_id, req_subject_id, 1);
        END IF;
    END LOOP;

    CLOSE request_cursor;
END //

DELIMITER ;