create or replace 
package body xx_service_request_pkg as

procedure create_sr(p_problem_summary IN VARCHAR2
                   ,p_severity IN VARCHAR2
                   ,p_complaint_type IN VARCHAR2
                   ,p_customer_number IN VARCHAR2
                   ,p_item_number IN VARCHAR2
				           ,p_organization IN VARCHAR2
                   ,p_group_name IN VARCHAR2
                   ,p_owner_name IN VARCHAR2
				           ,p_status     IN VARCHAR2
                   ,x_sr_number OUT VARCHAR2
                   ,x_status OUT VARCHAR2
                   ,x_err_message OUT VARCHAR2) IS
  lv_procedure_name     VARCHAR2(30) :='CREATE_SR';
  lx_msg_count          NUMBER;
  lx_msg_data           VARCHAR2(2000);
  lx_return_status      VARCHAR2(1);
  l_service_request_rec cs_servicerequest_pub.service_request_rec_type;
  l_notes_table         cs_servicerequest_pub.notes_table;
  l_contacts_tab        cs_servicerequest_pub.contacts_table;
  lx_sr_create_out_rec  cs_servicerequest_pub.sr_create_out_rec_type;
  v_user_id             NUMBER;
  v_resp_id             NUMBER;
  v_appl_id             NUMBER;
  lv_org_id             NUMBER;
  l_incident_type_id    NUMBER;
  ln_party_id           NUMBER;
  ln_account_id         NUMBER;
  v_country             VARCHAR2(10);
  lv_error_msg          VARCHAR2(4000);
  e_error               EXCEPTION;
  ln_organization_id    NUMBER;
  ln_item_id            NUMBER;
  ln_phone_id           NUMBER;
  ln_email_id           NUMBER;
  ln_severity_id        NUMBER;
  ln_resource_id        NUMBER;
  ln_status_group_id    NUMBER;
  ln_status_id          NUMBER;
BEGIN
  IF (p_complaint_type IS NOT NULL)
  AND (p_problem_summary IS NOT NULL) THEN
    BEGIN

    --fetch the incident type
    BEGIN
      SELECT incident_type_id,a.STATUS_GROUP_ID
        INTO l_incident_type_id,ln_status_group_id
        FROM cs_incident_types_rg_v_sec a
       WHERE incident_subtype = 'INC'
         AND name = p_complaint_type
         AND TRUNC(sysdate) BETWEEN TRUNC(NVL(start_date_active, sysdate)) AND TRUNC(NVL(end_date_active,sysdate));
    EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line('error in selecting the complaint type');
       lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect complaint type provided';
       RAISE e_error;
    END;

    BEGIN
	   SELECT party_id,cust_account_id
	     INTO ln_party_id,ln_account_id
		 FROM hz_cust_accounts
		WHERE account_number = p_customer_number
		  AND status = 'A';

	  EXCEPTION
    WHEN OTHERS THEN
	     dbms_output.put_line('Error in selecting the customer details');
	     lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect Customer Number provided';
	     RAISE e_error;
	  END;



      --fetch the party_id, country for the consumer
    v_country := NULL;
    BEGIN
	    SELECT country
	      INTO v_country
	      FROM hz_parties
	     WHERE party_id = ln_party_id;
    EXCEPTION
    WHEN OTHERS THEN
	    dbms_output.put_line('Error in selecting the party number');
	    lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect party country';
	    RAISE e_error;
    END;

    BEGIN
      SELECT CONTACT_POINT_ID
        INTO ln_email_id
        FROM hz_contact_points
       WHERE owner_table_id = ln_party_id
         AND owner_table_name = 'HZ_PARTIES'
         AND PRIMARY_FLAG = 'Y'
         AND contact_point_type = 'EMAIL';
    EXCEPTION
    WHEN OTHERS THEN
	    dbms_output.put_line('Error in selecting the email');
--	    lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect party country';
--	    RAISE e_error;
    END;

    BEGIN
      SELECT CONTACT_POINT_ID
        INTO ln_phone_id
        FROM hz_contact_points
       WHERE owner_table_id = ln_party_id
         AND owner_table_name = 'HZ_PARTIES'
         AND PRIMARY_FLAG = 'Y'
         AND contact_point_type = 'PHONE';
    EXCEPTION
    WHEN OTHERS THEN
	    dbms_output.put_line('Error in selecting phone Number');
--	    lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect party country';
--	    RAISE e_error;
    END;

	  BEGIN
      SELECT organization_id ,operating_unit
	    INTO ln_organization_id,lv_org_id
	    FROM org_organization_definitions
	   WHERE organization_name = p_organization;
	  EXCEPTION
    WHEN OTHERS THEN
	    dbms_output.put_line('Error in fetching operating unit details');
	    lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect operating unit provided';
	    RAISE e_error;
    END;

	BEGIN
    SELECT inventory_item_id
      INTO ln_item_id
      FROM mtl_system_items_b
     WHERE segment1 = p_item_number
     and organization_id = ln_organization_id;
	EXCEPTION
    WHEN OTHERS THEN
	  dbms_output.put_line('Error in fetching item  details');
	  lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect item provided';
  END;

	BEGIN
    SELECT INCIDENT_SEVERITY_ID
      INTO ln_severity_id
      FROM cs_incident_severities_tl
     WHERE description = p_severity;
	EXCEPTION
    WHEN OTHERS THEN
	  dbms_output.put_line('Error in fetching severity');
	  lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect severity provided';
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
         AND jv.group_name = p_group_name
         AND jvm.RESOURCE_NAME = p_owner_name
    ORDER BY 1;
	EXCEPTION
    WHEN NO_DATA_FOUND THEN
       ln_resource_id := -1;
    WHEN TOO_MANY_ROWS THEN
       ln_resource_id := -1;
    WHEN OTHERS THEN
	     dbms_output.put_line('Error in fetching resource  details');
       lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- unknown error while checking resource and group';
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
           AND resource_name = p_owner_name
      ORDER BY 1;
      EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('Error in fetching resource  details');
        lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect resource provided';
        RAISE e_error;
      END;
  END IF;

--Fetching sr status id
   BEGIN
      SELECT st.incident_status_id
        INTO ln_status_id
        FROM cs_incident_statuses st,
             cs_sr_allowed_statuses allowd_st
       WHERE allowd_st.incident_status_id = st.incident_status_id
         AND TRUNC(sysdate) BETWEEN TRUNC(NVL(allowd_st.start_date,sysdate)) AND TRUNC(NVL(allowd_st.end_date,sysdate))
         AND TRUNC(sysdate) BETWEEN TRUNC(NVL(st.start_date_active, sysdate)) AND TRUNC(NVL(st.end_date_active, sysdate))
         AND allowd_st.status_group_id         = ln_status_group_id
         AND st.NAME = p_status
         AND NVL(st.pending_approval_flag,'N')!='Y';
   EXCEPTION
     WHEN OTHERS THEN
       lv_error_msg := 'Error while getting incident status';
       raise e_error;
   END;


      --specify the SR attributes
      l_service_request_rec.request_date        := sysdate;
      l_service_request_rec.type_id             := l_incident_type_id;
      l_service_request_rec.business_process_id := 1000;
      l_service_request_rec.severity_id         := ln_severity_id;
      l_service_request_rec.summary             := SUBSTR(p_problem_summary, 1, 240); --limit problem_summary to 240 characters
      l_service_request_rec.caller_type         := 'ORGANIZATION';
      l_service_request_rec.status_id           := ln_status_id;
      l_service_request_rec.customer_id         := ln_party_id;
      l_service_request_rec.sr_creation_channel := 'PHONE';
      l_service_request_rec.verify_cp_flag      := 'N';
      l_service_request_rec.inventory_item_id   := ln_item_id;
      l_service_request_rec.inventory_org_id    := ln_organization_id;
      l_service_request_rec.customer_phone_id   := ln_phone_id;
      l_service_request_rec.customer_email_id   := ln_email_id;
      l_service_request_rec.owner_id            := ln_resource_id;
--	  l_service_request_rec.primary_flag        := 'Y';

      --all such SRs will be created from the INT_USER
      BEGIN
        SELECT user_id
        INTO v_user_id
        FROM apps.fnd_user
        WHERE upper(user_name) IN ('SYSADMIN');
      EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('Error in selecting the interface user');
      END;

      BEGIN
        SELECT fa.application_id,
          frt.responsibility_id
        INTO v_appl_id,
          v_resp_id
        FROM apps.fnd_user_resp_groups furg,
          apps.fnd_application fa,
          apps.fnd_responsibility_tl frt
        WHERE fa.application_short_name        = 'CSF'
        AND upper(frt.responsibility_name)     = upper('Field Service Manager, Vision Operations')
        AND fa.application_id                  = frt.application_id
        AND furg.responsibility_application_id = fa.application_id
        AND furg.responsibility_id             = frt.responsibility_id
        AND furg.user_id                       = 0
        AND rownum                             = 1;
      EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('Error in selecting the responsibility/application');
      END;

      --initializing the user
      apps.fnd_global.apps_initialize(
      user_id      => v_user_id,
      resp_id      => v_resp_id,
      resp_appl_id => v_appl_id);

      dbms_output.put_line('Before calling API');
      --create Service request API
      cs_servicerequest_pub.create_servicerequest(
      p_api_version              => 4.0,
      p_init_msg_list            => fnd_api.g_true,
      p_commit                   => fnd_api.g_false,
      x_return_status            => lx_return_status,
      x_msg_count                => lx_msg_count,
      x_msg_data                 => lx_msg_data,
      p_resp_appl_id             => v_appl_id,
      p_resp_id                  => v_resp_id,
      p_user_id                  => v_user_id,
      p_org_id                   => lv_org_id,
      p_request_id               => null,
      p_request_number           => null,
      p_service_request_rec      => l_service_request_rec,
      p_notes                    => l_notes_table,
      p_contacts                 => l_contacts_tab,
      p_auto_assign              => 'N',
      p_auto_generate_tasks      => 'N',
      x_sr_create_out_rec        => lx_sr_create_out_rec,
      p_default_contract_sla_ind => 'N');


      IF (lx_return_status = 'S') THEN
        COMMIT;
        dbms_output.put_line('Complaint has been registered:'||lx_sr_create_out_rec.request_number);
        x_status := 'S';
        x_err_message :='Complaint has been registered:'||lx_sr_create_out_rec.request_number;
        x_sr_number := lx_sr_create_out_rec.request_number;
      ELSE
        ROLLBACK;
        dbms_output.put_line('The complaint could not be registered:' || lx_msg_data);
        lv_error_msg := 'Service Request could not be created';
		RAISE e_error;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Unexpected Error ' || sqlerrm);
      lv_error_msg := 'Service Request could not be created';
	  RAISE e_error;
    END;
  ELSE
    lv_error_msg := 'Invalid input provided';
	RAISE e_error;
  END IF;
EXCEPTION WHEN e_error THEN
x_status := 'E';
x_err_message :=lv_error_msg;
WHEN OTHERS THEN
x_status := 'E';
x_err_message :='Unexpected error at create service request '||SQLERRM;
END;
PROCEDURE create_task(p_task_name IN VARCHAR2
                   ,p_task_type IN VARCHAR2
                   ,p_task_status IN VARCHAR2
                   ,p_task_priority IN VARCHAR2
                   ,p_customer_number IN VARCHAR2
                   ,p_incident_number IN VARCHAR2
--                   ,p_owner_type IN VARCHAR2
                   ,x_task_number OUT VARCHAR2
                   ,x_status OUT VARCHAR2
                   ,x_err_message OUT VARCHAR2) IS
  lv_procedure_name   VARCHAR2(30) :='CREATE_TASK';
  ln_user_id           NUMBER;
  ln_resp_id           NUMBER;
  ln_appl_id           NUMBER;
  l_msg_count         NUMBER;
  l_msg_data          VARCHAR2(2000);
  l_return_status     VARCHAR2(1);
  l_task_id           NUMBER;
  ln_resource_id       NUMBER;
  ln_incident_id       NUMBER;
  ln_task_type_id      NUMBER;
  ln_task_status_id    NUMBER;
  ln_task_priority_id  NUMBER;
  e_error             EXCEPTION;
  lv_error_msg        VARCHAR2(4000);
  lv_owner_type       VARCHAR2(100);
begin

  --the task is being created against Service Request#1000004940
  BEGIN
     SELECT incident_id,incident_owner_id,'RS_EMPLOYEE' resource_type
       INTO ln_incident_id,ln_resource_id,lv_owner_type
       FROM cs_incidents_all_b
      WHERE incident_number = p_incident_number;
   EXCEPTION WHEN OTHERS THEN
      dbms_output.put_line('error in selecting incident details');
      lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect incident number provided';
      RAISE e_error;
   END;
   BEGIN
      SELECT task_type_id
        INTO ln_task_type_id
        FROM jtf_task_types_tl
       WHERE NAME =p_task_type
	       AND language='US';
   EXCEPTION WHEN OTHERS THEN
      dbms_output.put_line('error in selecting task type');
      lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect task type provided';
      RAISE e_error;
   END;
   BEGIN
      SELECT task_status_id
        INTO ln_task_status_id
        FROM jtf_task_statuses_tl
       WHERE NAME=p_task_status
	       AND language='US';
         --And description='Task is open';
   EXCEPTION WHEN OTHERS THEN
      dbms_output.put_line('error in selecting task status');
      lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect task status provided';
      RAISE e_error;
   END;

   BEGIN
      SELECT task_priority_id
        INTO ln_task_priority_id
        FROM jtf_task_priorities_tl
       WHERE NAME=p_task_priority
	       AND language='US';
   EXCEPTION WHEN OTHERS THEN
      dbms_output.put_line('error in selecting task priority');
      lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- Incorrect task priority provided';
      RAISE e_error;
   END;
  --required for fnd_global.apps_initialize()
  SELECT user_id
    INTO ln_user_id
    FROM apps.fnd_user
   WHERE upper(user_name) IN ('SYSADMIN');

  --required for fnd_global.apps_initialize()
  SELECT fa.application_id, frt.responsibility_id
    INTO ln_appl_id, ln_resp_id
    FROM apps.fnd_user_resp_groups  furg,
         apps.fnd_application       fa,
         apps.fnd_responsibility_tl frt
   WHERE fa.application_short_name = 'CSF'
     AND upper(frt.responsibility_name) =
         upper('Field Service Manager, Vision Operations')
     AND fa.application_id = frt.application_id
     AND furg.responsibility_application_id = fa.application_id
     AND furg.responsibility_id = frt.responsibility_id
     AND furg.user_id = ln_user_id
     AND ROWNUM = 1;

  fnd_global.apps_initialize(user_id      => ln_user_id,
                                  resp_id      => ln_resp_id,
                                  resp_appl_id => ln_appl_id);

  --call the API
  jtf_tasks_pub.create_task(p_api_version             => 1.0,
                            p_init_msg_list           => fnd_api.g_true,
                            p_commit                  => fnd_api.g_false,
                            p_task_name               => p_task_name,
                            p_task_type_id            => ln_task_type_id,
                            p_task_status_id          => ln_task_status_id,
                            p_task_priority_id        => ln_task_priority_id,
                            p_owner_type_code         => lv_owner_type,
                            p_owner_id                => ln_resource_id,
                            p_show_on_calendar        => 'Y',
                            p_planned_start_date      => sysdate,
                            p_planned_end_date        => sysdate,
                            p_source_object_type_code => 'SR',
                            p_source_object_id        => ln_incident_id,
                            p_source_object_name      => NULL,
                            p_date_selected           => 'P',
                            x_return_status           => l_return_status,
                            x_msg_count               => l_msg_count,
                            x_msg_data                => l_msg_data,
                            x_task_id                 => l_task_id);

  if l_return_status <> fnd_api.g_ret_sts_success then
    dbms_output.put_line('Return Status aa= ' || l_return_status);
    dbms_output.put_line('Return Status dd= ' || fnd_api.g_ret_sts_success);
    dbms_output.put_line('l_msg_count aa= ' || l_msg_count);
    if l_msg_count > 0 then
      l_msg_data := null;
      for i in 1 .. l_msg_count loop
        l_msg_data := l_msg_data || ' ' || fnd_msg_pub.get(1, 'F');
        dbms_output.put_line('l_msg_data aa= ' || l_msg_data);
		lv_error_msg :=g_package_name ||'.' ||lv_procedure_name ||'- '||l_msg_data;
        RAISE e_error;
      end loop;
      fnd_message.set_encoded(l_msg_data);
      dbms_output.put_line(l_msg_data);
    end if;
    rollback;
  else
    dbms_output.put_line('Task Id = ' || l_task_id);
    dbms_output.put_line('Return Status = ' || l_return_status);
    x_status := 'S';
    x_err_message :='Task Id = ' || l_task_id;
    x_task_number := l_task_id;
    commit;
  end if;
EXCEPTION WHEN e_error THEN
x_status := 'E';
x_err_message :=lv_error_msg;
WHEN OTHERS THEN
x_status := 'E';
x_err_message :='Unexpected error at create task '||SQLERRM;
END;

end xx_service_request_pkg;