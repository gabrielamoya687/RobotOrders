*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Robocloud.Items
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    6x
${GLOBAL_RETRY_INTERVAL}=    3.0s
${PDFReceipts}=    C:/Users/E1365355/OneDrive - Emerson/RoboCorp Automations/robot-orders/output/PDFReceipts
${PNGReceipts}=    C:/Users/E1365355/OneDrive - Emerson/RoboCorp Automations/robot-orders/output/PNGReceipts
${PNG_Path}
${PDF_Path}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${csv_file_path}=    Collect CSV file from user
    Open the robot order website
    ${robots}=    Get Orders
    FOR    ${order}    IN    @{robots}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        ${pdf}=    Store the receipt as a PDF file    ${order}
        ${screenshot}=    Robot screenshot    ${order}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${order}
        Order another robot
    END
    Create ZIP package
    [Teardown]    Cleanup temporary directories
    Close Browser

*** Keywords ***
Collect CSV file from user
    Add heading    Upload CSV File
    Add file input
    ...    label=Upload the CSV file with order data
    ...    name=fileupload
    ...    file_type=CSV file (*.csv)
    ...    destination=${CURDIR}${/}output
    ${response}=    Run dialog
    [Return]    ${response.fileupload}[0]

Open the robot order website
    ${secrets_url}=    Get Secret    RobotOrdersURL
    Open Available Browser    ${secrets_url}[url]

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    Log    ${orders}
    [Return]    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    Preview
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order

Submit the order
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    id:order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Robot screenshot
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${PNGReceipts}${/}${order}[Order number]image.png

Store the receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:receipt
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${PDFReceipts}${/}${order}[Order number]order_receipt.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${order}
    Open Pdf    ${PDFReceipts}${/}${order}[Order number]order_receipt.pdf
    Add Watermark Image To Pdf    ${PNGReceipts}${/}${order}[Order number]image.png    ${PDFReceipts}${/}${order}[Order number]order_receipt.pdf
    Close Pdf

Order another robot
    Click Button    id:order-another

Create ZIP package
    ${zip_order_receipts}=    Set Variable    ${OUTPUT_DIR}/order_receipts.zip
    Archive Folder With Zip    ${PDFReceipts}    ${zip_order_receipts}

Cleanup temporary directories
    Remove Directory    ${PDFReceipts}    True

Read Secrets
    ${secrets_url}=    Get Secret    RobotOrdersURL
    Log    ${secrets_url}[url]
