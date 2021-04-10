# Gradle Enterprise:

## First time set up installation instructions: 
1. Follow the instructions on: https://docs.gradle.com/enterprise/kubernetes-admin/current/ using the keys provided by gradle:

        --customer-id=37df9aba01ee45505c4da5e2b618536c \
        --installation-id=DN8wc1mc6y4rN1AyxconigyGzXGkbJJA

2. Once you have generated those scripts, replace the scripts generated from the step above with the scripts inside the scripts directory: ./gradle-enterprise/scripts/.. 

3. Then you will need to set up access to the Factory cluster using: https://cyclones.atlassian.net/wiki/spaces/LEAPIMPL/pages/1444211203/EKS+Access

4. Once you are successfully connected to the Factory cluster through the eksaccess container, go into the ~/git/factory/gradle-enterprise and run the following to set up a namespace using: 

        kubectl apply -f gradle-namespace.yaml

    then you can run the install script from ~/git/factory/gradle-enterprise/scripts : 

        ./install.sh

    which will install Gradle Enterprise into the Factory Cluster.

5. Once the gradle-proxy is up and running, go ahead and install the ingress: 

        kubectl apply -f gradle-ingress.yaml

    Once all pods are up and working you should be able to access the instances if you are on the correct network. 

6. To initialize the Gradle Enterprise instance head over to: www.gradle.factory.digi-leap.net/init/admin where you will be asked for an initialization key.  
This key can found by searching for `GEADM_INIT__INIT_KEY` variable in gradle_enterprise.yml.  
Once you enter that key, you will be prompted to set up a system account and will have the choice to pick a password. Please use something secure. 

7. After this is done, click on 'Add New Users' and then you will be able to set up new users and pick what level of access to provide to them, starting with the developer credentials below under 'To Access'.

### To Access:
URL: gradle.factory.digi-leap.net  
Developer Username: developer  
Developer Password: Passw0rd  

Additionoal Notes:
To get around the issue of gradle-build-cache not starting:
- create a new storage class called gp2-wait that has the wait for first client before provisioning PV
- delete the 2 build-cache PVCs
- modify the build-cache PVC yamls to use new gp2-wait storage class
- apply the new PVCs
and they should provision the PVs with the same AZ. 