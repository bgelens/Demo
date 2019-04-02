using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using testapp.Models;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.KeyVault;

namespace testapp.Controllers
{
    public class HomeController : Controller
    {
        public async Task<IActionResult> Index()
        {
            var tokenProvider = new AzureServiceTokenProvider();
            var vaultClient = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(tokenProvider.KeyVaultTokenCallback));

            var keyvaultName = Environment.GetEnvironmentVariable("keyvaultname");
            var keyvaultSecret = Environment.GetEnvironmentVariable("keyvaultsecret");
            var keyvaultUri = $"https://{keyvaultName}.vault.azure.net/secrets/{keyvaultSecret}";

            var secret = await vaultClient.GetSecretAsync(keyvaultUri).ConfigureAwait(false);
            ViewBag.Secret = secret.Value;

            return View();
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
