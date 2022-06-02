# Autox: Automatically trigger Iter8 experiments
Autox is an Iter8 feature that launches experiments automatically in Kubernetes when new versions of Kubernetes resources are created. The following is an **example** of how autox can be used. This is intended to set up autox to kick start `load-test-http` experiments based on deployment triggers.

## 1.a Create experiment group config

Configure the experiment group in Kubernetes in preparation for autox. Be sure to supply the autox release name and autox release namespace (to be discussed below). This step does not start an experiment... it prepares the ground for autox to launch experiments in this group in the future. This includes creating the experiment spec secret.

```shell
iter8 k install -c load-test-http -g hello -n test \
--set url=http://httpbin.test/get \
--set autox.releaseName=autoxslos \
--set autox.releaseNamespace=default
```
The above command creates the RBAC permissions needed for the experiment job/cronjob to work, and permissions to read the group spec secret. The group spec secret has references to the experiment chart.

## 1.b Delete experiment group config
This step undoes 1.a.

```shell
iter8 k delete -g hello -n test
```

## 2.a Install autox

The following command installs the autox controller. In this example, the autox controller is installed in the `default` (Helm release) namespace, but automates experiments in the `test` namespace. The name of the autox release is `autoxslos`.
```shell
helm install autoxslos iter8/autox \
--set triggers[0].namespace=test \
--set triggers[0].kind=deployment
```
For the above command to work, the autox chart will need to install appropriate RBAC permissions in the trigger namespaces. Specifically, in the above example, there needs to be permissions to watch deployments in the `test` namespace.

### 2.b Uninstall autox
Use `helm uninstall`. This step undoes 2.a.

## 3. Trigger experiment
The following creates a deployment with the right annotation, in order to trigger the experiment.
```shell
kubectl create deployment nginx --image=nginx -n test
kubectl annotate deploy/nginx iter8.tools/group=hello -n test
```

Steps 1.a, 2.a, and 3 are all required to auto trigger an experiment.

## 4. Report experiment results

A few seconds later, you can view the report for the auto launched experiment using familiar `iter8` commands.
```shell
iter8 k report -g hello -n test
```

## 5. Automatically remove an autox experiment (`autox-unlaunch`)
```shell
# notice the minus sign at the end of the annotation
kubectl annotate deploy/nginx iter8.tools/group- -n test
```

## 6. Remove an experiment group from autox
You can `helm upgrade` the autox release in Step 2, and follow this up with step 1.b

***

**Known limitations:** 
1. The above interaction is not GitOps friendly. This is because of the use of `iter8` experiment charts instead of `helm` charts in steps 1.a and 1.b. We will revisit this question after an initial implementation of autox that accomplishes the above.
2. What happens if the autox deployment restarts? In the MVP implementation, it will relaunch experiments in every experiment group for which the old trigger and new trigger have a different checksums. Eventually, we will also support [diffing customization](https://argo-cd.readthedocs.io/en/stable/user-guide/diffing/) like argo cd.
3. Adding further to 1.) above, we do not want the order of `autox` and `iter8 k` to matter in the above steps. E.g., ArgoCD might be used to perform 1.a and 2.a in which case, the order is not deterministic.