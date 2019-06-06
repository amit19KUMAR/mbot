module.exports = (robot) ->
    executionId=0

    #URLs for localhost:8080
    # MODULE_URL = "http://localhost:8080/MIST/mindtree/projectNames?tenantID=1"
    # GENERATE_REPORT = "http://localhost:8080/MIST/mindtree/project/getJsonReportByModuleName?moduleName="
    # EXECUTE_PROJECT = "http://localhost:8080/MIST/mindtree/project/executeProject?projectName="
    # GENERATE_CURRENT_REPORT = "http://localhost:8080/MIST/mindtree/report/generateReport"
    # DOWNLOAD_FILE = "http://localhost:8080/MIST/mindtree/report/downloadFile?executionId="

    #URLs for cloud
    MODULE_URL = "http://mindtree-dtep.southeastasia.cloudapp.azure.com:8080/MIST/mindtree/projectNames?tenantID=1"
    GENERATE_REPORT = "http://mindtree-dtep.southeastasia.cloudapp.azure.com:8080/MIST/mindtree/project/getJsonReportByModuleName?moduleName="
    EXECUTE_PROJECT = "http://mindtree-dtep.southeastasia.cloudapp.azure.com:8080/MIST/mindtree/project/executeProject?projectName="
    GENERATE_CURRENT_REPORT = "http://mindtree-dtep.southeastasia.cloudapp.azure.com:8080/MIST/mindtree/report/generateReport"
    DOWNLOAD_FILE = "http://mindtree-dtep.southeastasia.cloudapp.azure.com:8080/MIST/mindtree/report/downloadFile?executionId="

    robot.hear /(hi|hello)/i, (res) ->
        res.send "HI!! I am mbot. What Can I do for You?"

    #Weather API
    robot.hear /(weather|temperature|temp)/i, (msg) ->
        msg.http("http://api.apixu.com/v1/current.json?key=ff2c1b4e107149a79c3110822192503&q=Bengaluru")
            .get() (err , res , body) ->
                try 
                    json = JSON.parse(body)
                    msg.send "Weather Details: \n
                    location: #{json.location.name}\n
                    temperature: #{json.current.temp_c} *C"
                catch   
                    msg.send "Could not catch the weather."

    #Jokes API
    robot.hear /(jokes|joke)/i, (msg) ->
        msg.http("https://sv443.net/jokeapi/category/Programming")
            .get() (err, res, body) ->
                try
                    json = JSON.parse(body)
                    msg.send "#{json.joke}"
                catch
                    msg.send "No Jokes.....!!!!"

    #Mist Project Execution API
    # robot.hear /(Execute|Execution)/i, (msg) ->
    #     msg.http("http://localhost:8080/MIST/mindtree/project/executeProject?projectName=Trial")
    #         .post() (err, res, body) ->
    #             try 
    #                 # json = JSON.parse(body)
    #                 # msg.send "#{body}\n#{err}\n#{res}"
    #                 msg.send "Execution Completed"
    #             catch
    #                 msg.send "Connection Failed"

    #Mist Modules/Projects available
    robot.hear /Modules Available|projects|modules/i, (msg) ->
        msg.http(MODULE_URL)
            .post() (err, res, body) ->
                res1 = JSON.parse(body)
                len=Object.keys(res1).length
                i=1
                resp="*Modules Available* are : \n \n"
                try
                    while i<=len
                        resp+="> *#{i}* : "+res1[i]+"\n"
                        i++
                    msg.send "#{resp}"
                catch
                    msg.send "Connection Failed"

    robot.hear /Log/i, (msg) ->
        msg.send "Enter The Project/Module Name: (command - *report [Project Name]*)"

    #Report generate For Specific Module
    robot.hear /report (.*)/i, (msg) ->
        reportExt = msg[Object.keys(msg)[1]].rawMessage.text
        projName = reportExt.substring(7) 
        msg.http(GENERATE_REPORT+projName)
            .get() (err, res, body) ->
                JsonRes = JSON.parse(body)
                
                
                try
                    msg.send ">>>*Report:*\n
                    *Module:* \t #{projName} \n
                    *Start Time :*\t #{JsonRes.startTime}\n
                    *Test Suite :*\t #{JsonRes.suites[0].testSuiteName} \n\t\t\t\t\t _status :_\t  #{JsonRes.suites[0].status} \n
                    *Test Case :*\t #{JsonRes.suites[0].Cases[0].testCaseName} \n\t\t\t\t\t _status :_\t #{JsonRes.suites[0].Cases[0].status}\n
                    \n\t\t\t _Test Case Value :_ \t #{JsonRes.suites[0].Cases[0].Steps[0].value} \n\t\t\t _status :_\t #{JsonRes.suites[0].Cases[0].Steps[0].status}\n"
                catch
                    msg.send "Something Went Wrong!!"

    robot.hear /(features|feature|help)/i, (msg) ->
        msg.send ">>>*Features Are:*\n 
        Modules/Projects available - *modules available*\n
        Ask For Project Execution - *Run*\n
        Direct Project Execution - *execute [Project Name]*\n
        Ask For Log/Report - *Log*\n
        Report generate - *report [Project Name]*\n
        Download Latest Report - command - *Download Report*\n"

    # robot.hear /(.*)/, (msg) ->
    #     console.log "starting--------------------------------------------"
    #     console.log typeof(msg)
    #     console.log msg[Object.keys(msg)[1]].rawMessage.text

    robot.hear /Run/i, (msg) ->
        msg.send "Enter Project Name to Execute -(command - *execute [Project Name]*)"

    robot.hear /execute (.*)/, (resp) ->
                projExt = resp[Object.keys(resp)[1]].rawMessage.text
                # console.log proj.substring(8)
                proj=projExt.substring(8)
                resp.send "*Execution Started...*"
                resp.http(EXECUTE_PROJECT+proj)
                    .post() (err, res, body) ->
   
                        executionId = body
                        
                        try
                            if res[Object.keys(res)[20]]=='OK'
                                resp.send "*Execution Finished*"
                                resp.http(GENERATE_CURRENT_REPORT)
                                    .headers('executionId': executionId)
                                    .get() (e,r,b) ->
                                        try
                                            resp.send "\t\t*Report Generated*"
                                        catch
                                            resp.send "\t\t*Failed To Generate Report*"
                            else if res[Object.keys(res)[20]]=="Internal Server Error"
                                resp.send "Project Does Not Exist"
                            else
                                resp.send "*Connection Error* :#{res[Object.keys(res)[20]]}"
                        catch
                            resp.send "*Execution Failed*"    
    
    robot.hear /Download Report/i, (msg) ->
        
        open = require('open')
        if executionId==0
            msg.send "No Latest report Available...Please Run A Module First"
        else
            try
                console.log executionId
                download_file_url = DOWNLOAD_FILE+executionId
                data = JSON.parse ('{
                            "text": "Download REPORT",
                            "channel": "C061EG9SL",
                            "attachments": [
                                {
                                    "fallback": "Test link button to https://slack.com/",
                                    "actions": [
                                        {
                                            "type": "button",
                                            "text": "Download",
                                            "url": "'+download_file_url+'",
                                            "style": "primary"
                                        }
                                    ]
                                }
                            ]
                        }')
                
                msg.send data  
            catch
                msg.send "Exception Occured"