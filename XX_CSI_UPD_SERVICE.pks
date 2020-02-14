create or replace 
PACKAGE XX_CSI_UPD_SERVICE AS

g_package_name VARCHAR2(100) := 'XX_CSI_UPD_SERVICE';
PROCEDURE update_service_request(p_sr_number IN VARCHAR2
                                 ,p_summary IN VARCHAR2
                                 ,p_item_number IN VARCHAR2
                                 ,p_status_name IN VARCHAR2
                                 ,p_severity IN VARCHAR2
                                 ,p_sr_type IN VARCHAR2
                                 ,x_status_code OUT VARCHAR2
                                 ,x_message OUT VARCHAR);

PROCEDURE update_task(p_task_number IN VARCHAR2
                                 ,p_sr_number IN VARCHAR2
                                 ,p_description IN VARCHAR2
                                 ,p_status_name IN VARCHAR2
                                 ,p_resource_name IN VARCHAR2
--                                 ,p_scheduled_start_date IN DATE
                                 ,x_status_code OUT VARCHAR2
                                 ,x_message OUT VARCHAR);
                                 
END XX_CSI_UPD_SERVICE;