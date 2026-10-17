
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export KUBECONFIG="$HOME/.kube/prod:$HOME/.kube/l3s"

# gbrain: respect repo .gitignore when walking code sources (skip vendor/, dist/, var/, build artifacts)
export GBRAIN_RESPECT_GITIGNORE=true
