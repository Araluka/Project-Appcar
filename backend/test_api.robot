*** Settings ***
Library  RequestsLibrary

*** Variables ***
${API_URL}  http://localhost:3000/api/bookings
${EXPECTED_STATUS_CODE}  200
${AUTH_TOKEN}  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MywiZW1haWwiOiJuYW5hQGV4YW1wbGUuY29tIiwibmFtZSI6Ik5hbmEiLCJyb2xlIjoiY3VzdG9tZXIiLCJpYXQiOjE3NTMxNzkyNjgsImV4cCI6MTc1Mzc4NDA2OH0.Any6vdDQSsVQOp6TzthwiahGtTukShpKbduXKlGILNs
${BOOKING_DATA}  {"car_id": 2, "booking_date": "2025-07-07", "start_time": "2025-07-23T09:00:00", "end_time": "2025-07-23T17:00:00", "driver_required": true}

*** Test Cases ***
Create Booking API Should Return Status 200
    ${headers}=  Create Dictionary  Authorization=Bearer ${AUTH_TOKEN}  Content-Type=application/json
    ${response}=  POST  ${API_URL}  headers=${headers}  json=${BOOKING_DATA}
    Log  ${response.content}  INFO
    ${status_code}=  Get Response Status Code  ${response}
    Should Be Equal As Numbers  ${status_code}  ${EXPECTED_STATUS_CODE}

*** Keywords ***
Get Response Status Code
    [Arguments]  ${response}
    ${status_code}=  Get Response Status Code  ${response}
    RETURN  ${status_code}
