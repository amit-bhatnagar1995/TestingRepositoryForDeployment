namespace JobToSendMail
{
    using System.Net;
    using System.Configuration;
    using System.IO;

    class Program
    {
        /// <summary>
        /// Hits the URL of resource dashboard to send mails to the person(s) concerned.
        /// </summary>
        /// <param name="args"></param>
        static void Main(string[] args)
        {
            string url = ConfigurationManager.AppSettings["PublishedAppURL"];
            int jobIteratorCounter;
            for(jobIteratorCounter = 1; jobIteratorCounter < 5; jobIteratorCounter++)
            {
                string recursiveURL = url;
                recursiveURL += jobIteratorCounter;

                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(recursiveURL);
                request.AutomaticDecompression = DecompressionMethods.GZip;

                using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
                {
                    using (Stream stream = response.GetResponseStream())
                    {
                        // Do nothing
                    }
                }
            }
        }
    }
}
