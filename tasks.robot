*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...               Order URL: https://robotsparebinindustries.com/#/robot-order
...               CSV URL: https://robotsparebinindustries.com/orders.csv
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Dialogs
Library           RPA.Archive
Library           RPA.Robocorp.Vault

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    30x
${GLOBAL_RETRY_INTERVAL}=    0.2s
${GLOBAL_WAIT_TIMEOUT}=    0.3s

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orderurl}=    Read data from the vault
    ${csvurl}=    Input form dialog
    Open the robot order website    ${orderurl}
    ${orders}=    Get orders    ${csvurl}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Populate One Order    ${row}
        ${pdf}=    Set Variable    ${OUTPUT_DIR}${/}SalesReceipt${/}receipt_${row}[Order number].pdf
        ${receipt_html}=    Store the receipt as a HTML    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${receipt_html}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Log out and close the browser

*** Keywords ***
Read data from the vault
    ${secret}=    Get Secret    url
    Log    ${secret}[order-url]
    [Return]    ${secret}[order-url]

Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}

Close the annoying modal
    Wait Until Page Contains Element    css:.btn-dark    timeout=${GLOBAL_WAIT_TIMEOUT}
    Click Button    css:.btn-dark

Get orders
    [Arguments]    ${url}
    Download the Excel file    ${url}
    ${csvfile}=    CSV to Table
    [Return]    ${csvfile}

Input form dialog
    Add heading    URL of the orders CSV file?
    Add text input    url    label=URL
    ${result}=    Run dialog
    [Return]    ${result.url}

Download the Excel file
    [Arguments]    ${url}
    Download    ${url}    overwrite=True

CSV to Table
    ${csvfile}=    Read table from CSV    orders.csv
    [Return]    ${csvfile}

Populate One Order
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    #Input Text    css:.form-control    ${row}[Legs]
    #Input Text    css:input[class="form-control"]    ${row}[Legs]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    preview
    Wait Until Page Contains Element    robot-preview-image    timeout=${GLOBAL_WAIT_TIMEOUT}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Click Order Button and check the result

Click Order Button and check the result
    Click Button    order
    Wait Until Element Is Visible    css:.badge.badge-success    timeout=${GLOBAL_WAIT_TIMEOUT}

Store the receipt as a HTML
    [Arguments]    ${order_number}
    ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    [Return]    ${order_receipt}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Page Contains Element    id:robot-preview-image    timeout=${GLOBAL_WAIT_TIMEOUT}
    ${path_screenshot}    Set Variable    ${OUTPUT_DIR}${/}Screenshots${/}screenshot_${order_number}.png
    Screenshot    id:robot-preview-image    ${path_screenshot}
    [Return]    ${path_screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${receipt_html}    ${pdf}
    Html To Pdf
    # ...    ${receipt_html}<br><br><center><img src='${screenshot}' height='200'/></center>
    # ...    ${receipt_html}<br><br><style> img {display: block; margin-left: auto; margin-right: auto} </style><img src='${screenshot}' height='200'/>
    # ...    ${receipt_html}<br><br><img src='${screenshot}' height='200' style="display: block; margin-left: auto; margin-right: auto;" />
    # ...    ${receipt_html}<html><head></head><body><br>normal<br><strong>strong</strong><br><em>em</em><br><i>italic</i><br><b>bold</b><br><img src="${screenshot}" style="display: block; margin-left: auto; margin-right: auto; width:5%;" /></body></html>
    ...    ${receipt_html}
    ...    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/SalesReceipts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}SalesReceipt
    ...    ${zip_file_name}

Log out and close the browser
    Close Browser
