# Production Dockerfile for ibkr_trade_mcp
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/ibkr_trade_mcp

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/ibkr_trade_mcp /app/bin/ibkr_trade_mcp

ENTRYPOINT ["/app/bin/ibkr_trade_mcp"]
