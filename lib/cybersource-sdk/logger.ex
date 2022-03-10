defmodule CyberSourceSDK.Logger do
  @moduledoc """
  Logger
  """
  require Logger

  def info(it) do
    if should_log?() do
      Logger.info("[CyberSourceSDK] #{it}")
    end
  end

  def error(it) do
    Logger.error("[CyberSourceSDK] #{it}")
  end

  defp should_log? do
    Application.get_env(:cybersource_sdk, :debug)
  end
end
