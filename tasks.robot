*** Settings ***
Documentation     Robot to buy new robots from excel sheet and place order on RobotSpareBinIndustries.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Robocloud.Secrets
Library           RPA.Dialogs

*** Keywords ***
Open The Website
    ${urlsecret}=      Get Secret     secret_url
    Open Available Browser           ${urlsecret}[URL]
    Maximize Browser Window
    Click Button    OK

*** Keywords ***
Download The Excel file
    Add heading       Please enter the link for the .csv file
    Add text          https://robotsparebinindustries.com/orders.csv
    Add text input    url

    ${response}=      Run dialog
    [Return]      ${response.url}

*** Keywords ***
Fill And Submit The Form
    [Arguments]    ${order_entry}
    Select From List By Index   head    ${order_entry}[Head]
    ${target_as_string}=    Convert To String    ${order_entry}[Body]
    Click Button When Visible      id:id-body-${target_as_string}
    Input Text        xpath://div[3]/input  ${order_entry}[Legs]
    Input Text        id:address        ${order_entry}[Address]
    Sleep    1s
    Click Button When Visible    id:preview
    Wait Until Element Is Visible    id:order

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]     ${path}

    FOR    ${i}    IN RANGE    10
        
        ${Check}=   Is Element Visible    id:order
        IF    ${Check} == True
            Click Button    id:order
        Exit For Loop If    ${Check} == False
        END
    END

    Wait Until Element Is Visible    id:receipt
    Sleep    1s
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${path}
    [Return]    ${path}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${path}
    Click Element When Visible    xpath://img[@alt='Head']
    Click Element When Visible    xpath://img[@alt='Body']
    Click Element When Visible    xpath://img[@alt='Legs']

    Capture Element Screenshot    xpath://div[@id='robot-preview-image']      ${path}
    [Return]    ${path}



*** Keywords ***
Go to order another robot
    Sleep    1s
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another
    Wait And Click Button    css:.btn-dark

*** Keyword ***
ZIP archive
     Archive Folder With Zip  ${CURDIR}${/}outputs${/}receipt  receipts.zip  recursive=True  include=*.pdf  exclude=/.*


*** Tasks ***
Order Robots and store it is PDF
    Open The Website
    Download The Excel file
    ${order_entries}=  Read table from CSV    orders.csv
    FOR    ${order_entry}    IN    @{order_entries}
        Fill And Submit The Form    ${order_entry}
        ${pdf}=  Store the receipt as a PDF file   ${CURDIR}${/}outputs${/}receipt${/}receipt-${order_entry}[Order number].pdf
        ${screenshot}=  Take a screenshot of the robot    ${CURDIR}${/}outputs${/}images${/}screenshot-${order_entry}[Order number].png
        Open Pdf     ${pdf}
        Add Watermark Image To Pdf
    ...    image_path=${screenshot}
    ...    output_path=${pdf}
        Close Pdf    ${pdf}
        Go to order another robot
    END
    [Teardown]   Close Browser
    ZIP archive
