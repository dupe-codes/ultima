## a vault of useful code snippets

### ocaml - use of lwt for promise handling

```ocaml
(*
  Example of using lwt to handle promises.

  count_requests uses lwt to resolve the inner_handler promise,
  thus counting successes if the promise is successfully resolved
  and failures if the promise is rejected or fails, signaled
  by the raising of an ocaml exn
 *)

let successful = ref 0
let failed = ref 0

let count_requests inner_handler request =
  try%lwt
    let%lwt response = inner_handler request in
    successful := !successful + 1;
    Lwt.return response

  with exn ->
    failed := !failed + 1;
    raise exn

let () =
  Dream.run
  @@ Dream.logger
  @@ count_requests
  @@ Dream.router [

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The Web app failed!"));

    Dream.get "/" (fun _ ->
      Dream.html (Printf.sprintf
        "%3i request(s) successful<br>%3i request(s) failed"
        !successful !failed));

  ]
```
