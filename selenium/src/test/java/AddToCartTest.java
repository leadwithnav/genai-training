import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.NoAlertPresentException;
import org.testng.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import java.time.Duration;

public class AddToCartTest {
    private WebDriver driver;

    @BeforeClass
    public void setUp() {
        driver = new ChromeDriver();
        driver.manage().window().maximize();
    }

    @Test
    public void testAddToCart_Step1to4() {
        driver.get("http://localhost:3000");
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

        // Step 1: Wait for the first "Add to Cart" button to be visible
        WebElement addToCartBtn = wait.until(
            ExpectedConditions.visibilityOfElementLocated(By.xpath("//button[text()='Add to Cart']"))
        );

        // Step 2: Click the first "Add to Cart" button (select a product)
        addToCartBtn.click();

        // Step 3: Wait for and accept the alert dialog
        try {
            wait.until(ExpectedConditions.alertIsPresent());
            driver.switchTo().alert().accept();
        } catch (NoAlertPresentException e) {
            Assert.fail("Expected alert was not present after adding to cart.");
        }

        // Step 4: Wait for the cart count in the header to update and check it
        WebElement cartLink = wait.until(
            ExpectedConditions.visibilityOfElementLocated(By.xpath("//a[starts-with(text(),'Cart (')]"))
        );
        String cartText = cartLink.getText();
        // Extract the number from "Cart (N)"
        int count = 0;
        try {
            count = Integer.parseInt(cartText.replaceAll("[^0-9]", ""));
        } catch (NumberFormatException e) {
            Assert.fail("Could not parse cart count from: " + cartText);
        }
        Assert.assertTrue(count > 0, "Cart count did not increment.");
    }

    @AfterClass
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
