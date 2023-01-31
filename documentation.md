# **Full pipeline**
---------------------

## **This document describes the full pipelie line of the JAVA project with the follwig stages .**
  * git checkout
  * build & SonarQube analysis
  * Quality Gate
  * junit testResults
  * rtServer (artifactory configuration) , rtMavenDeployer (repository choosing )
  * rtMavenRun (execute maven goals)
  * Publish build info
  * Build docker image
  * pushing image from local to jfrog repo
  * ![preview](img/2.png)

* ## prereusites 
   * jenkins setup with atleast one node
   * installed java and maven on the node
   * configure maven  in manage jenkins -> global tool conguration 
      * this is used in 'rtMavenRun tool section'. 
             
         ![preview](img/1.png).
      * configure sonarqube in manage jenkins -> system configuration
      * ![preview](img\.png)
    *  docker pipeline plugin installed. 
    * write jenkis file where the code is present . ie SCM
    * a branchig strategy ( here we follw github branching strategy ie. here we have four branches every branch a pipeline on the dev branch for every commit we triggr the build. on the testing branch we configure cronjob  )
    * 
* ### we use git method to checkout 
   ```bash
    git url: 'https://github.com/vikashpudi/spring-petclini.git', 
        branch: 'main'
   ```
  ![preview](img/3.png)
* ###  build & SonarQube analysis
  ```bash
   stage("build & SonarQube analysis") {
            steps {
              sh' echo ***********SONAR SCANING************************'
              withSonarQubeEnv('sonarqube') {
                sh "mvn package sonar:sonar"}
              }
            }
  ```
* ###  Quality Gate stage
  ```bash
  stage("Quality Gate") {
            steps {
              sh' echo ***********QUALITY GATE************************'
              timeout(time: 30, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true
              }
            }
          }
  ```
*  ### junit testResults
  ```
  junit testResults: 'target/surefire-reports/*.xml'
  ```
*  ### rtServer 
  ```bash
   rtServer (
                  id: 'Artifactory',
                  url: 'https://beatyourlimits.jfrog.io/artifactory/',
                  credentialsId: 'jfrog',
                   bypassProxy: true,
                   timeout: 300
                       )
  ```
   * id: this will be used when ever uwant your server configuration
   * url: this is our artifactory url 
   * credentialsId : give the id which u configure in the jenkis credentals
       manage jenkins -> manage credentials
        ![](img/4.png)
*  ### rtMavenDeployer
``` bash
    rtMavenDeployer (
                        id: "spc_DEPLOYER",
                        serverId: "Artifactory",
                        releaseRepo: "demo",
                        snapshotRepo: "snapdemo"
                                )
```
    * id will be used in further steps
    * give id whic u haven given in rtserver
    * give the repositery names where u want to preserve the artifact
*  ###  rtMavenRun
  ```bash
  rtMavenRun (
                    tool: "maven", // Tool name from Jenkins configuration
                     pom: "pom.xml",
                     goals: "install ",
                     deployerId: "spc_DEPLOYER"
                 )
  ```
    * tool: which was given in global tools
    * pom: path of your pm.xml file
    * goals: maven goals
    * deployerId : wich was given in the rtMavenDeployers id section
*  ### Publish build info
```bash 
rtPublishBuildInfo (
                    serverId: "Artifactory"
                )
```
 * after uploading publish the details in the jenkins build page
* ## building docker image
  * buid the docker image using build package for this we need to write the docker file. nad that docker file also placed where the code is present i.e git
  the docker file is 
  ```Dockerfile
              FROM amazoncorretto:11
              ADD  ./spring-petclinic-2.7.3.jar /
              WORKDIR /
              EXPOSE 8080
              CMD ["java","-jar","spring-petclinic-2.7.3.jar"]

  ``` 
      ![](img/5.png)
  * if the build the code in the same node then the packae is in the target folder. copy the jar file from that location.or  if u using multiple nodes use stash and unstash or by using curl download the package .
  * here in this case we r using curl request
    ```bash
    this command is used to download the artifact from the jfrog repositery
  curl -u "pudivikash:Devops@123456" -X GET https://beatyourlimits.jfrog.io/artifactory/demo/org/springframework/samples/spring-petclinic/2.7.4/spring-petclinic-2.7.4.jar --output spring-petclinic-2.7.4.jar
    ```
* ## pushing image from local to  jfrog docker register
  * after building the image from jar file which was build in previous stage by using the docker file.
  * for this we have servral options 
      * shellcommands
      * rtDockerpush
      * docker pipeline plugin
  * here we are follow docker pipeling plug in. the following is the script for the pushing the image.
   ![](img\6.png)
  ```bash
  script{
              //  def image = "spc:${BUILD_ID}"
              def app
                app = docker.build  "mydockerrepo/spc:${BUILD_ID}"
                docker.withRegistry('https://beatyourlimits.jfrog.io/artifactory/mydockerrepo', 'jfrog') {            
				        app.push("${env.BUILD_NUMBER}")
	        }    
  ```
  * docker.withRegistry requries two arguments 
                          1. repositery url
                          2. jfrog creditnals id (configured in credentals section of mangae jenkins section )

 *  ![](img\7.png)

* ## kubernetes secres
  * here i configure the kubectl maually . need to figure out the optimal way
  ```bash
  kubectl create secret docker-registry jfrogsecret --docker-server=beatyourlimits.jfrog.io --docker-username=pudivikash@gmail.com --docker-password=Devops@123456 --docker-email=pudivikash@gmail.com
  ``` 
  ![](img\8.png)
   
  To pull docker images from private registry we need to pass these secrets in the `Deployment.spec.template.spec.imagePullSecrets`

  
  * **deploymnent manifest**
      ```yaml
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: springpetclinceployment
            spec:
              minReadySeconds: 10
              replicas: 1
              selector:
                matchLabels:
                  app: spc
              strategy:
                rollingUpdate:
                  maxSurge: 25
                  maxUnavailable: 25
                type: RollingUpdate
              template:
                metadata:
                  name: tempspecspc
                  labels:
                    app: spc
                spec:
                  containers:
                  - image: beatyourlimits.jfrog.io/mydockerrepo/spc:46
                    name: spc
                    ports:
                      - containerPort: 8080
                  imagePullSecrets:
                    - name: jfrogsecret
      ```
* but the challange over here is u need update the the image in manifest for ever build. this can be sloved by helm or kustamize.**yet to lern** .










  ---------------------------------------------------------------------------------------------------------------------------------------------
  
  
* this command is used to download the artifact from the jfrog repositery
  curl -u "pudivikash:Devops@123456" -X GET https://beatyourlimits.jfrog.io/artifactory/demo/org/springframework/samples/spring-petclinic/2.7.3/spring-petclinic-2.7.3.jar --output spring-petclinic-2.7.3.jar
----------------------------------------------------------------------------------------------------
* when i run docker image build command manually in node it works but when it runs from jenkins it show demon error. `solutuion --->  sudo chmod 777 /var/run/docker.sock`  (why)
* -------------------------------------------------------------------------------------------------------
* vzhkgclht4j77v7fmsrvoib6lwgpsi3nqvjsk7pf2fturfdj3nza