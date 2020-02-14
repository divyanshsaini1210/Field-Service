create or replace 
PACKAGE XX_SERVICE_REQUEST_PKG AUTHID CURRENT_USER AS

/*#
* This custom package is used to provide EBS REST services for POC.
* @rep:scope public
* @rep:product AZ
* @rep:displayname XX_SERVICE_REQUEST_PKG
* @rep:lifecycle active
* @rep:compatibility S
* @rep:category BUSINESS_ENTITY PER_EMPLOYEE
*/

/*#
* Returns ServiceRequestResponse
* @param p_problem_summary        VARCHAR2       p_problem_summary
* @param p_severity               VARCHAR2       p_severity
* @param p_complaint_type         VARCHAR2       p_complaint_type
* @param p_customer_number        VARCHAR2       p_customer_number
* @param p_item_number            VARCHAR2       p_item_number
* @param p_organization           VARCHAR2       p_organization
* @param p_group_name             VARCHAR2	 p_group_name
* @param p_owner_name             VARCHAR2	 p_owner_name
* @param p_status                 VARCHAR2       p_status
* @param x_sr_number              VARCHAR2       x_sr_number
* @param x_status                 VARCHAR2       x_status
* @param x_err_message            VARCHAR2       x_err_message
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Return ServiceRequestDetails
*/

Procedure create_sr (p_problem_summary IN VARCHAR2
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
                   ,x_err_message OUT VARCHAR2);

/*#
* Returns CreatTaskResponse
* @param p_task_name        VARCHAR2       p_task_name
* @param p_task_type        VARCHAR2       p_task_type
* @param p_task_status      VARCHAR2       p_task_status
* @param p_task_priority    VARCHAR2       p_task_priority
* @param p_customer_number  VARCHAR2       p_customer_number
* @param p_incident_number  VARCHAR2       p_incident_number
* @param x_task_number      VARCHAR2       x_sr_number
* @param x_status           VARCHAR2       x_status
* @param x_err_message      VARCHAR2       x_err_message
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Return TaskDetails
*/


procedure create_task(p_task_name IN VARCHAR2
                   ,p_task_type IN VARCHAR2
                   ,p_task_status IN VARCHAR2
                   ,p_task_priority IN VARCHAR2
                   ,p_customer_number IN VARCHAR2
                   ,p_incident_number IN VARCHAR2
                   ,x_task_number OUT VARCHAR2
                   ,x_status OUT VARCHAR2
                   ,x_err_message OUT VARCHAR2);


g_package_name  VARCHAR2(30) := 'XX_SERVICE_REQUEST_PKG';

end xx_service_request_pkg;
