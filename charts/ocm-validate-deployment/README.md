# Load Test with SLOs

Use this Iter8 experiment chart to verify that an application, defined by an `AppBundle` has
been deployed to a sufficient number of edge clusters.

***

## Examples

The following `iter8 run` command will verify that within *5s* the `AppBundle` *candidate* is deployedd to all of the test clusters. Test clusters are defined by the placement identified in *candidate*.

```shell
iter8 run --set candidate=candidate \
          --set timeout=5s \
          --set SLOs.error-rate=0
```
