# StreamWhere API: Ruby on Rails edition

A Ruby on Rails rebuild of the availability API behind **[StreamWhere](https://www.streamwhere.online)**, my live streaming-availability site, which runs on Next.js and Node/Express in production.

I built this to learn Rails properly by porting something real, and to compare the two stacks on the same problem. It answers one question: **where can I watch this title, in each country?**

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/search?q=dune&page=1` | Films and series matching a query (people are filtered out) |
| GET | `/api/v1/titles/:media_type/:id/availability` | Where a title is available, for every country |
| GET | `/api/v1/titles/:media_type/:id/availability?country=GB` | The same for one country |
| GET | `/up` | Health check |

`media_type` is `movie` or `tv`; `id` is a TMDB id.

### Example

```bash
curl "localhost:3000/api/v1/titles/movie/438631/availability?country=GB"
```

```json
{
  "id": 438631,
  "media_type": "movie",
  "country": "GB",
  "offers": {
    "stream": ["HBO Max", "NOW", "ITVX Premium"],
    "free": ["ITVX"],
    "rent": ["Apple TV", "Rakuten TV", "Amazon", "Sky Store", "YouTube"],
    "buy": ["Apple TV", "Rakuten TV", "Amazon", "Sky Store", "YouTube"],
    "link": "https://www.themoviedb.org/movie/438631-dune/watch?locale=GB"
  }
}
```

## Design

```
app/
  controllers/api/v1/
    base_controller.rb          rate limiting, error → status mapping
    search_controller.rb
    availability_controller.rb  input validation, caching
  services/
    tmdb/client.rb              TMDB HTTP client (Net::HTTP, timeouts, typed errors)
    availability/normalizer.rb  raw provider data → stream / free / rent / buy
```

- **Thin controllers, plain Ruby service objects.** The HTTP client and the normalising logic know nothing about Rails, so they're easy to unit test.
- **Normalisation** turns TMDB's raw provider lists into clean answers. It merges duplicate service names ("Now TV Cinema" → "NOW", "Amazon Prime Video with Ads" → "Prime Video"), removes "… Amazon Channel" suffixes, doesn't list a free-with-ads service that's already in the subscription list, and sorts the main markets first.
- **Errors map to accurate status codes:** bad input → `400` (rejected before any upstream call), unknown title → `404`, TMDB down or timing out → `502`. Every error comes back as `{"error": "..."}` JSON.
- **Caching:** provider data is cached for 6 hours and searches for 10 minutes using `Rails.cache`. Responses also send `Cache-Control` headers so CDNs and browsers can cache them.
- **Rate limiting** uses Rails 8's built-in `rate_limit` (60 requests a minute per IP).
- **No database:** this service only transforms upstream data, so Active Record is left out.

## Tests

```bash
bin/rails test      # 14 tests, no network: TMDB is stubbed with WebMock
bin/rubocop         # style
bin/brakeman        # security static analysis
```

The tests cover the normaliser, input validation, error mapping (404, 502, timeouts), and a check that a second request is served from cache without calling TMDB again. GitHub Actions runs the tests, RuboCop, Brakeman and bundler-audit on every push.

## Running locally

Requires Ruby 3.4 and a free [TMDB API key](https://www.themoviedb.org/settings/api).

```bash
bundle install
TMDB_API_KEY=your_key bin/rails server
```

## Node/Express vs Rails: what I noticed

| | StreamWhere (Express) | This (Rails) |
|---|---|---|
| Structure | One large `index.js` of route handlers | Conventions push you into controllers + service objects from the start |
| Rate limiting | `express-rate-limit` package | Built in (`rate_limit`) |
| Caching | Hand-rolled in-memory object with a timestamp | `Rails.cache.fetch` with `expires_in` |
| Error handling | `try/catch` in each route | `rescue_from` once, in a base controller |
| Testing | None yet | Minitest + WebMock from day one |

Rails' conventions gave me a cleaner structure than the original with less code, and some of these patterns are worth bringing back into the Express version.

---

Data from [TMDB](https://www.themoviedb.org/) and JustWatch. This product uses the TMDB API but is not endorsed or certified by TMDB.
