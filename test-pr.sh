
TAG=$(date +"%Y-%m-%d-%H%M%S")
PR_NAME=docker-build-run-$TAG
PR_TMP=$(mktemp)
NS=$(oc project --short)

REVISION=$1
if [ -z $REVISION ]; then
REVISION=main
fi 
cat << EOF >$PR_TMP 
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata: 
  labels:
    pipelines.openshift.io/runtime: generic
    pipelines.openshift.io/strategy: docker
    pipelines.openshift.io/used-by: build-cloud
    tekton.dev/pipeline: docker-build
  name: $PR_NAME
spec:
  params:
  - name: git-url
    value: https://github.com/jduimovich/code-with-quarkus
  - name: revision
    value: "$REVISION" 
  - name: output-image
    value: image-registry.openshift-image-registry.svc:5000/$NS/code-with-quarkus:$REVISION
  - name: dockerfile
    value: https://raw.githubusercontent.com/jduimovich/devfile-sample-code-with-quarkus/fast-and-uber/src/main/docker/Dockerfile.jvm.staged
  pipelineRef:
    name: docker-build 
  workspaces:
  - name: workspace
    volumeClaimTemplate: 
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF

echo "Pipeline name is $PR_NAME"  
kubectl apply -f $PR_TMP 
echo "watch pipeline run via tkn pipelinerun  logs $PR_NAME  -f"