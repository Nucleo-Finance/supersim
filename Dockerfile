# The base image for the supersim image can be modified
# by specifying BASE_IMAGE build argument
ARG BASE_IMAGE=golang:1.22

# New build argument for L1 node URL
ARG L1_NODE_URL=http://172.21.0.2:8545

#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
#
#           This stage builds the foundry binaries
#
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
FROM $BASE_IMAGE AS foundry

# Make sure foundryup is available
ENV PATH="/root/.foundry/bin:${PATH}"

# Install required system packages
RUN \
    apt-get update && \
    apt-get install -y curl git

# Install foundry
RUN curl -L https://foundry.paradigm.xyz | bash
RUN foundryup

#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
#
#                 This stage builds the project
#
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
FROM $BASE_IMAGE AS builder

RUN git init
RUN git submodule init
RUN git submodule update --init --recursive

WORKDIR /app

COPY . .

RUN go mod tidy
RUN go build -o supersim cmd/main.go

#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
#
#            This stage exposes the supersim binary
#
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
FROM $BASE_IMAGE AS runner

# Pass the L1_NODE_URL as an environment variable
ARG L1_NODE_URL
ENV L1_NODE_URL=${L1_NODE_URL}

# Add foundry & supersim directories to the system PATH
ENV PATH="/root/.foundry/bin:/root/.supersim/bin:${PATH}"

WORKDIR /app

COPY --from=foundry /root/.foundry/bin /root/.foundry/bin

COPY --from=builder /app /app

RUN chmod +x /app/deploy-l1.sh

# Get the supersim binary from the builder
COPY --from=builder /app/supersim /root/.supersim/bin/supersim

# Make sure the required binaries exist
RUN anvil --version
RUN supersim --help

# We'll use supersim as the entrypoint to our image
# 
# This allows the consumers to pass CLI options as the command to docker run:
# 
# docker run supersim --help
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]