# The base image for the supersim image can be modified
# by specifying BASE_IMAGE build argument
ARG BASE_IMAGE=golang:1.22

# New build argument for L1 node URL
ARG L1_NODE_URL=http://127.0.0.1:8545

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

WORKDIR /app

COPY . .

RUN git clone https://github.com/ethereum-optimism/optimism.git \
    -b op-contracts/v1.3.0 --depth=1 \
    && cd optimism/packages/contracts-bedrock \
    && git submodule update --depth=1 --recursive --init lib/*

RUN cd optimism && go mod tidy
RUN go mod tidy

#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
#
#            This stage exposes the entrypoint binary
#
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
FROM $BASE_IMAGE AS runner

# Pass the L1_NODE_URL as an environment variable
ARG L1_NODE_URL
ENV L1_NODE_URL=${L1_NODE_URL}

# Add foundry directories to the system PATH
ENV PATH="/root/.foundry/bin:${PATH}"

WORKDIR /app

COPY --from=foundry /root/.foundry/bin /root/.foundry/bin
COPY --from=builder /app /app

RUN chmod +x /app/deploy-l1.sh

# Make sure the required binaries exist
RUN anvil --version

RUN apt-get update \
    && apt-get install --no-install-recommends -y jq net-tools

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]