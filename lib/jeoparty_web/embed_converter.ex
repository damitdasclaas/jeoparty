defmodule JeopartyWeb.EmbedConverter do
  @moduledoc """
  Converts video URLs from various platforms into their embed URLs.
  Currently supports:
  - YouTube (youtube.com/watch?v=, youtu.be/, youtube.com/embed/)
  - Vimeo
  - Dailymotion
  """

  @doc """
  Converts a video URL to its embed URL.
  Returns {:ok, embed_url} on success or {:error, reason} on failure.
  """
  def convert_url(nil), do: {:error, :invalid_url}
  def convert_url(url) when is_binary(url) do
    cond do
      is_youtube_url?(url) -> {:ok, get_youtube_embed(url)}
      is_vimeo_url?(url) -> {:ok, get_vimeo_embed(url)}
      is_dailymotion_url?(url) -> {:ok, get_dailymotion_embed(url)}
      true -> {:error, :unsupported_platform}
    end
  end
  def convert_url(_), do: {:error, :invalid_url}

  @doc """
  Transforms a video URL to its embed format.
  Unlike convert_url/1, this function:
  - Returns the embed URL directly (no tuple)
  - Returns the original URL if not recognized
  - Used primarily for data storage
  """
  def transform_video_url(url) when is_binary(url) do
    case convert_url(url) do
      {:ok, embed_url} -> embed_url
      _ -> url
    end
  end
  def transform_video_url(url), do: url

  # YouTube URL patterns
  defp is_youtube_url?(url) do
    String.match?(url, ~r/^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)/)
  end

  defp get_youtube_embed(url) do
    cond do
      # Handle youtube.com/watch?v= URLs
      video_id = Regex.run(~r/youtube\.com\/watch\?v=([^&]+)/, url) ->
        "https://www.youtube.com/embed/#{Enum.at(video_id, 1)}"

      # Handle youtu.be/ URLs
      video_id = Regex.run(~r/youtu\.be\/([^?]+)/, url) ->
        "https://www.youtube.com/embed/#{Enum.at(video_id, 1)}"

      # Handle youtube.com/embed/ URLs (already in correct format)
      Regex.match?(~r/youtube\.com\/embed\//, url) ->
        url

      true -> nil
    end
  end

  # Vimeo URL patterns
  defp is_vimeo_url?(url) do
    String.match?(url, ~r/^(https?:\/\/)?(www\.)?vimeo\.com/)
  end

  defp get_vimeo_embed(url) do
    case get_vimeo_id(url) do
      nil -> nil
      id -> "https://player.vimeo.com/video/#{id}"
    end
  end

  defp get_vimeo_id(url) do
    case Regex.run(~r/vimeo\.com\/(\d+)/, url) do
      [_, id] -> id
      _ -> nil
    end
  end

  # Dailymotion URL patterns
  defp is_dailymotion_url?(url) do
    String.match?(url, ~r/^(https?:\/\/)?(www\.)?dailymotion\.com/)
  end

  defp get_dailymotion_embed(url) do
    case get_dailymotion_id(url) do
      nil -> nil
      id -> "https://www.dailymotion.com/embed/video/#{id}"
    end
  end

  defp get_dailymotion_id(url) do
    case Regex.run(~r/dailymotion\.com\/video\/([a-zA-Z0-9]+)/, url) do
      [_, id] -> id
      _ -> nil
    end
  end
end
