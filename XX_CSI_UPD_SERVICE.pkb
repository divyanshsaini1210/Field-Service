create or replace 
PACKAGE BODY XX_CSI_UPD_SERVICE AS
PROCEDURE update_service_request(p_sr_number IN VARCHAR2
                                 ,p_summary IN VARCHAR2
                                 ,p_item_number IN VARCHAR2
                                 ,p_status_name IN VARCHAR2
                                 ,p_severity IN VARCHAR2
                                 ,p_sr_type IN VARCHAR2
                                 ,x_status_code OUT VARCHAR2
                                 ,x_message OUT VARCHAR) IS
lv_procedure_name VARCHAR2(100):= 'UPDATE_SERVICE_REQUEST';
e_error           EXCEPTION;
l_return_status              VARCHAR2(1);
l_msg_count                  NUMBER;
l_msg_data                   VARCHAR2(1000);
l_msg_dummy                  VARCHAR2 (4000) ;
l_output                     VARCHAR2 (15000);
l_last_update_date           DATE   := SYSDATE ;
l_service_request_rec        cs_servicerequest_pub.service_request_rec_type;
l_notes                      cs_servicerequest_pub.notes_table;
l_contacts                   cs_servicerequest_pub.contacts_table;
l_sr_update_out_rec          cs_servicerequest_pub.sr_update_out_rec_type;
l_workflow_process_id       NUMBER;
l_interaction_id            NUMBER;
l_user_id                   NUMBER;
l_resp_id                   number;
l_resp_appl_id              NUMBER;
ln_type_id                  NUMBER;
ln_status_group_id          NUMBER;
ln_severity_id              NUMBER;
ln_status_id                NUMBER;
ln_ovn_id                   NUMBER;
ln_incident_id              NUMBER;
--ln_severity_id              NUMBER;
BEGIN
--Fetching user id for initialization
   BEGIN
      SELECT user_id
      INTO l_user_id
      FROM fnd_user
      WHERE user_name = 'SYSADMIN';
   EXCEPTION
     WHEN OTHERS THEN
       l_user_id := NULL;
   END;
--Fetching resp id and app id for initialization  
   BEGIN
      SELECT responsibility_id, application_id
      INTO l_resp_id, l_resp_appl_id
      FROM fnd_responsibility_vl
      WHERE responsibility_name = 'Field Service Manager, Vision Operations';
   EXCEPTION
     WHEN OTHERS THEN
       l_resp_id       := NULL;
       l_resp_appl_id  := NULL;
   END;
--Fetching sr type id  
   BEGIN
      SELECT incident_type_id,a.STATUS_GROUP_ID
        INTO ln_type_id,ln_status_group_id
        FROM cs_incident_types_rg_v_sec a
       WHERE incident_subtype = 'INC'
         AND name = p_sr_type
         AND TRUNC(sysdate) BETWEEN TRUNC(NVL(start_date_active, sysdate)) AND TRUNC(NVL(end_date_active,sysdate));
   EXCEPTION
     WHEN OTHERS THEN
       l_msg_data := 'Error while getting incident type';
       raise e_error;
   END;
--Fetching sr status id  
   BEGIN
      SELECT   st.incident_status_id
        INTO ln_status_id
      FROM cs_incident_statuses st,
        cs_sr_allowed_statuses allowd_st
      WHERE allowd_st.incident_status_id = st.incident_status_id
      AND TRUNC(sysdate) BETWEEN TRUNC(NVL(allowd_st.start_date,sysdate)) AND TRUNC(NVL(allowd_st.end_date,sysdate))
      AND TRUNC(sysdate) BETWEEN TRUNC(NVL(st.start_date_active, sysdate)) AND TRUNC(NVL(st.end_date_active, sysdate))
      AND allowd_st.status_group_id         = ln_status_group_id
      AND st.NAME = p_status_name
      AND NVL(st.pending_approval_flag,'N')!='Y';
   EXCEPTION
     WHEN OTHERS THEN
       l_msg_data := 'Error while getting incident status';
       raise e_error;
   END;

--Fetching sr default details 
   BEGIN
      SELECT object_version_number,a.incident_id
        INTO ln_ovn_id,ln_incident_id
        FROM cs_incidents_all a
       WHERE incident_number = p_sr_number
         AND incident_status_id not in (select incident_status_id from cs_incident_statuses_vl where close_flag = 'Y');
   EXCEPTION
     WHEN OTHERS THEN
       l_msg_data := 'Error while getting incident detail';
       raise e_error;
   END;
	BEGIN
    SELECT INCIDENT_SEVERITY_ID
      INTO ln_severity_id
      FROM cs_incident_severities_tl
     WHERE description = p_severity;
	EXCEPTION
    WHEN OTHERS THEN
	  dbms_output.put_line('Error in fetching item  details');
	  l_msg_data :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect item provided';
	  RAISE e_error;  
  END;
---Initializing session
fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id);
mo_global.init ('CSF');
cs_servicerequest_pub.initialize_rec( l_service_request_rec);

--Assign variable
l_service_request_rec.external_attribute_11 := p_item_number;
l_service_request_rec.SUMMARY := p_summary;
l_service_request_rec.status_id := ln_status_id;
--l_service_request_rec.inventory_item_id := 9898;
l_service_request_rec.type_id := ln_type_id;
l_service_request_rec.severity_id := ln_severity_id;
--Calling update API
CS_ServiceRequest_PUB.Update_ServiceRequest (p_api_version            => 3.0,
                                             p_init_msg_list          => FND_API.G_FALSE,
                                             p_commit                 => FND_API.G_FALSE,
                                             x_return_status          => l_return_status,
                                             x_msg_count              => l_msg_count,
                                             x_msg_data               => l_msg_data,
                                             p_request_id             => ln_incident_id,--&incident_id,
                                             p_request_number         => NULL,
                                             p_audit_comments         => NULL,
                                             p_object_version_number  => ln_ovn_id, --&object_version_number,
                                             p_resp_appl_id           => NULL,                                                                                                                                                                                                                                         --fnd_global.resp_appl_id,
                                             p_resp_id                => NULL,                                                                                                                                                                                                                                                                                           --fnd_global.resp_id,
                                             p_last_updated_by        => NULL,                                                                                                                                                                                                                                                                                   --fnd_global.user_id,
                                             p_last_update_login      => NULL,
                                             p_workflow_process_id    => NULL,
                                             p_last_update_date       => l_last_update_date,
                                             p_service_request_rec    => l_service_request_rec,
                                             p_notes                  => l_notes,
                                             p_contacts               => l_contacts,
                                             p_called_by_workflow     => FND_API.G_FALSE,
                                             x_workflow_process_id    => l_workflow_process_id,
                                             x_interaction_id         => l_interaction_id );
      IF (l_return_status = 'S') then
        COMMIT;
        x_status_code :='S';
      ELSE
        ROLLBACK;
         BEGIN
           FOR i IN 1 .. l_msg_count
           LOOP
               fnd_msg_pub.get (i,
                                fnd_api.g_false,
                                l_msg_data,
                                l_msg_dummy);
                l_output := (TO_CHAR (i) || ': ' || l_msg_data);
           END LOOP;
           raise e_error;
         END;
               DBMS_OUTPUT.PUT_LINE ('Error :'||l_output);
       END IF;


EXCEPTION 
  WHEN e_error THEN
    x_status_code :='E';
    x_message :=l_msg_data;
  WHEN OTHERS THEN
    x_status_code :='E';
    x_message :='Unknown error while updating SR :'||SQLERRM;    
END update_service_request;

PROCEDURE update_task(p_task_number IN VARCHAR2
                                 ,p_sr_number IN VARCHAR2
                                 ,p_description IN VARCHAR2
                                 ,p_status_name IN VARCHAR2
                                 ,p_resource_name IN VARCHAR2
--								 ,p_scheduled_start_date IN DATE
                                 ,x_status_code OUT VARCHAR2
                                 ,x_message OUT VARCHAR) IS
 
   lv_procedure_name                            VARCHAR2(100):= 'UPDATE_TASK';
   e_error                                      EXCEPTION;
   l_object_ver_num                             jtf_tasks_v.object_version_number%TYPE;
   l_task_status_id                             jtf_tasks_v.task_status_id%TYPE := 9;
   l_task_status_name                           jtf_tasks_v.task_status%TYPE;
   l_task_id                                    jtf_tasks_v.task_id%TYPE;
   l_task_number                                jtf_tasks_v.task_number%TYPE;
   l_return_status                              VARCHAR2 (1);
   l_msg_count                                  NUMBER;
   l_msg_data                                   VARCHAR2 (1000);
   l_user_id                   NUMBER;
   l_resp_id                   number;
   l_resp_appl_id              NUMBER;
   lv_object_name                               VARCHAR2(2000);
   lv_object_type                               VARCHAR2(2000);
   ln_task_id                                   NUMBER;
   ln_st_count                                  NUMBER;
   ln_sr_id                                     NUMBER;
   ln_status_id                                 NUMBER;
   ln_resource_id                               NUMBER;
BEGIN

   BEGIN
      SELECT task_id,source_object_type_code,source_object_name,object_version_number,source_object_id,task_status_id
	    INTO ln_task_id,lv_object_type,lv_object_name,l_object_ver_num,ln_sr_id,ln_status_id
        FROM jtf_tasks_b
       WHERE task_number = p_task_number
         AND source_object_type_code = 'SR'
         AND source_object_name = p_sr_number;
   
   EXCEPTION
      WHEN OTHERS THEN
      dbms_output.put_line('Error in fetching task  details');
      l_msg_data :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect task number provided';
      RAISE e_error;   
   END;

   BEGIN
   
        SELECT count(0)
          INTO ln_st_count
        FROM jtf_task_statuses_vl state ,
          jtf_state_responsibilities sr,
          jtf_state_rules_vl rules ,
          jtf_state_transitions trans
        WHERE sr.responsibility_id   = fnd_global.resp_id
        AND sr.rule_id               = rules.rule_id
        AND rules.state_type         = 'TASK_STATUS'
        AND ((trans.initial_state_id =ln_status_id
        AND trans.final_state_id = state.task_status_id
        AND rules.rule_id        = trans.rule_id
        AND trans.rule_id       IS NOT NULL))
        AND TRUNC(sysdate) BETWEEN TRUNC(NVL(state.start_date_active, sysdate)) AND TRUNC(NVL(state.end_date_active, sysdate));
        
        IF ln_st_count >0 THEN
          SELECT state.task_status_id
            INTO l_task_status_id
            FROM jtf_task_statuses_vl state ,
              jtf_state_responsibilities sr,
              jtf_state_rules_vl rules ,
              jtf_state_transitions trans
            WHERE sr.responsibility_id   = fnd_global.resp_id
            AND sr.rule_id               = rules.rule_id
            AND rules.state_type         = 'TASK_STATUS'
            AND ((trans.initial_state_id =ln_status_id
            AND trans.final_state_id = state.task_status_id
            AND rules.rule_id        = trans.rule_id
            AND trans.rule_id       IS NOT NULL))
            AND upper(state.name) = upper(p_status_name)
            AND TRUNC(sysdate) BETWEEN TRUNC(NVL(state.start_date_active, sysdate)) AND TRUNC(NVL(state.end_date_active, sysdate));
        ELSE
           
           SELECT task_status_id
             INTO l_task_status_id
             FROM jtf_task_statuses_tl
            WHERE NAME=p_status_name 
              AND language='US';
        END IF;
        
        
   EXCEPTION
      WHEN OTHERS THEN
      dbms_output.put_line('Error in fetching status  details');
      l_msg_data :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect status provided';
      RAISE e_error;   
   END;
   
	BEGIN
      SELECT  jvm.resource_id
        INTO ln_resource_id
        FROM jtf_rs_resource_extns_vl cjr,
             JTF_RS_GROUPS_VL jv,
             jtf_rs_group_members_vl jvm
       WHERE TRUNC (SYSDATE) BETWEEN NVL (TRUNC (cjr.start_date_active),TRUNC (SYSDATE))
         AND NVL (TRUNC (cjr.end_date_active), TRUNC (SYSDATE))
         AND cjr.CATEGORY = 'EMPLOYEE'
         AND cjr.resource_id = jvm.resource_id
         AND jv.group_id= jvm.group_id
         AND jv.group_name = (select group_owner from cs_incidents_all where incident_id =ln_sr_id )
         AND jvm.RESOURCE_NAME = p_resource_name
    ORDER BY 1;
	EXCEPTION
    WHEN NO_DATA_FOUND THEN
       ln_resource_id := -1;
    WHEN TOO_MANY_ROWS THEN
       ln_resource_id := -1;
    WHEN OTHERS THEN
	     dbms_output.put_line('Error in fetching item  details');
       l_msg_data :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect resource and group provided';
	      RAISE e_error;  
  END;
  IF ln_resource_id = -1 THEN
      BEGIN
        SELECT resource_id
          INTO ln_resource_id
          FROM jtf_rs_resource_extns_vl
         WHERE TRUNC (SYSDATE) BETWEEN NVL (TRUNC (start_date_active),TRUNC (SYSDATE))
           AND NVL (TRUNC (end_date_active), TRUNC (SYSDATE))
           AND CATEGORY = 'EMPLOYEE'
           AND resource_name = p_resource_name
      ORDER BY 1;
      EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('Error in fetching resource  details');
        l_msg_data :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect resource provided';
        RAISE e_error;  
      END;
  END IF;   
   
   
--Fetching user id for initialization
   BEGIN
      SELECT user_id
      INTO l_user_id
      FROM fnd_user
      WHERE user_name = 'SYSADMIN';
   EXCEPTION
     WHEN OTHERS THEN
       l_user_id := NULL;
   END;
--Fetching resp id and app id for initialization  
   BEGIN
      SELECT responsibility_id, application_id
      INTO l_resp_id, l_resp_appl_id
      FROM fnd_responsibility_vl
      WHERE responsibility_name = 'Field Service Manager, Vision Operations';
   EXCEPTION
     WHEN OTHERS THEN
       l_resp_id       := NULL;
       l_resp_appl_id  := NULL;
   END;
---Initializing session
fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id);
   JTF_TASKS_PUB.UPDATE_TASK (p_api_version                           => 1.0
                            , p_init_msg_list                         => fnd_api.g_true
                            , p_commit                                => fnd_api.g_false
                            , p_object_version_number                 => l_object_ver_num
                            , p_description                           => p_description
                            , p_task_number                           => p_task_number
                            , p_task_status_id                        => l_task_status_id
                            , p_source_object_type_code               => lv_object_type
                            , p_source_object_name                    => lv_object_name
                            , p_owner_id                              => ln_resource_id
--                            , p_scheduled_start_date                   => p_scheduled_start_date
                            , x_return_status                         => l_return_status
                            , x_msg_count                             => l_msg_count
                            , x_msg_data                              => l_msg_data
                             );


   IF (l_return_status != 'S') then
   
      IF l_msg_count > 0
      THEN
         l_msg_data                                     := NULL;

         FOR i IN 1 .. l_msg_count
         LOOP
            l_msg_data                                     := l_msg_data || ' ' || fnd_msg_pub.get (1, 'F');
         END LOOP;

         fnd_message.set_encoded (l_msg_data);
         DBMS_OUTPUT.put_line (SUBSTR (l_msg_data
                                     , 1.1
                                     , 200
                                      ));
      END IF;
        raise e_error;
   ELSE
      COMMIT;
      x_status_code :='S';
      x_message := 'Task updated';
   END IF;

EXCEPTION 
  WHEN e_error THEN
    x_status_code :='E';
    x_message :=l_msg_data;
  WHEN OTHERS THEN
    x_status_code :='E';
    x_message :='Unknown error while updating SR :'||SQLERRM;  
END;
                                 
END XX_CSI_UPD_SERVICE;